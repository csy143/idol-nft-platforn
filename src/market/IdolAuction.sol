// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../tokens/IdolCard.sol";

contract IdolAuction is Ownable, ReentrancyGuard {
    IdolCard public immutable idolCard;
    
    struct Auction {
        address seller;          // 卖家
        uint256 startingPrice;   // 起拍价
        uint256 minIncrement;    // 最小加价幅度
        uint256 startTime;       // 开始时间
        uint256 endTime;         // 结束时间
        address highestBidder;   // 最高出价人
        uint256 highestBid;      // 最高出价
        bool ended;              // 是否结束
    }
    
    // tokenId => Auction
    mapping(uint256 => Auction) public auctions;
    // tokenId => bidder => amount
    mapping(uint256 => mapping(address => uint256)) public bids;
    
    // 费率（以基点表示，1% = 100）
    uint256 public feeRate = 250; // 2.5%
    
    event AuctionCreated(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startingPrice,
        uint256 startTime,
        uint256 endTime
    );
    
    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 amount
    );
    
    event AuctionEnded(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 amount
    );
    
    event BidWithdrawn(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 amount
    );
    
    constructor(address _idolCard) Ownable(msg.sender) {
        idolCard = IdolCard(_idolCard);
    }
    
    // 创建拍卖
    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 minIncrement,
        uint256 duration
    ) external {
        require(startingPrice > 0, "Starting price must be > 0");
        require(minIncrement > 0, "Min increment must be > 0");
        require(duration >= 1 hours, "Duration too short");
        require(duration <= 7 days, "Duration too long");
        require(idolCard.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(idolCard.getApproved(tokenId) == address(this), "Auction not approved");
        
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        
        auctions[tokenId] = Auction({
            seller: msg.sender,
            startingPrice: startingPrice,
            minIncrement: minIncrement,
            startTime: startTime,
            endTime: endTime,
            highestBidder: address(0),
            highestBid: 0,
            ended: false
        });
        
        emit AuctionCreated(tokenId, msg.sender, startingPrice, startTime, endTime);
    }
    
    // 出价
    function placeBid(uint256 tokenId) external payable nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(!auction.ended, "Auction ended");
        require(block.timestamp >= auction.startTime, "Auction not started");
        require(block.timestamp < auction.endTime, "Auction expired");
        
        uint256 newBid = bids[tokenId][msg.sender] + msg.value;
        require(newBid >= auction.startingPrice, "Bid too low");
        
        if (auction.highestBid > 0) {
            require(newBid >= auction.highestBid + auction.minIncrement, "Bid increment too low");
        }
        
        // 更新出价记录
        bids[tokenId][msg.sender] = newBid;
        
        // 更新最高出价
        if (newBid > auction.highestBid) {
            auction.highestBid = newBid;
            auction.highestBidder = msg.sender;
        }
        
        emit BidPlaced(tokenId, msg.sender, newBid);
    }
    
    // 结束拍卖
    function endAuction(uint256 tokenId) external nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(!auction.ended, "Auction already ended");
        require(
            block.timestamp >= auction.endTime || msg.sender == auction.seller,
            "Cannot end auction yet"
        );
        
        auction.ended = true;
        
        if (auction.highestBidder != address(0)) {
            // 计算费用
            uint256 fee = (auction.highestBid * feeRate) / 10000;
            uint256 sellerProceeds = auction.highestBid - fee;
            
            // 转移NFT给赢家
            idolCard.safeTransferFrom(auction.seller, auction.highestBidder, tokenId);
            
            // 转账给卖家
            (bool success, ) = auction.seller.call{value: sellerProceeds}("");
            require(success, "Transfer to seller failed");
        }
        
        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }
    
    // 提取出价（未中标者）
    function withdrawBid(uint256 tokenId) external nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(auction.ended, "Auction not ended");
        require(msg.sender != auction.highestBidder, "Winner cannot withdraw");
        
        uint256 amount = bids[tokenId][msg.sender];
        require(amount > 0, "No bids to withdraw");
        
        bids[tokenId][msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit BidWithdrawn(tokenId, msg.sender, amount);
    }
    
    // 获取当前最高出价信息
    function getHighestBid(uint256 tokenId) external view returns (address, uint256) {
        Auction storage auction = auctions[tokenId];
        return (auction.highestBidder, auction.highestBid);
    }
    
    // 获取用户在某拍卖中的出价
    function getUserBid(uint256 tokenId, address user) external view returns (uint256) {
        return bids[tokenId][user];
    }
} 