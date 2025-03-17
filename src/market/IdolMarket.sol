// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../tokens/IdolCard.sol";

contract IdolMarket is Ownable, ReentrancyGuard {
    IdolCard public immutable idolCard;
    
    // 市场上的商品结构
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }
    
    // tokenId => Listing
    mapping(uint256 => Listing) public listings;
    
    // 费率（以基点表示，1% = 100）
    uint256 public feeRate = 250; // 2.5%
    
    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Unlisted(uint256 indexed tokenId);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event FeeRateUpdated(uint256 newFeeRate);
    
    constructor(address _idolCard) Ownable(msg.sender) {
        idolCard = IdolCard(_idolCard);
    }
    
    // 上架NFT
    function listToken(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(idolCard.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(idolCard.getApproved(tokenId) == address(this), "Market not approved");
        
        listings[tokenId] = Listing(msg.sender, price, true);
        
        emit Listed(tokenId, msg.sender, price);
    }
    
    // 下架NFT
    function unlistToken(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.seller == msg.sender, "Not seller");
        require(listing.isActive, "Not listed");
        
        listing.isActive = false;
        emit Unlisted(tokenId);
    }
    
    // 购买NFT
    function buyToken(uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.isActive, "Not listed");
        require(msg.value >= listing.price, "Insufficient payment");
        
        listing.isActive = false;
        
        // 计算费用
        uint256 fee = (listing.price * feeRate) / 10000;
        uint256 sellerProceeds = listing.price - fee;
        
        // 转移代币
        idolCard.safeTransferFrom(listing.seller, msg.sender, tokenId);
        
        // 转移资金
        (bool success, ) = listing.seller.call{value: sellerProceeds}("");
        require(success, "Transfer to seller failed");
        
        emit Sold(tokenId, listing.seller, msg.sender, listing.price);
    }
    
    // 更新费率（仅所有者）
    function setFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= 1000, "Fee rate too high"); // 最高10%
        feeRate = newFeeRate;
        emit FeeRateUpdated(newFeeRate);
    }
    
    // 提取合约中的费用（仅所有者）
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Fee withdrawal failed");
    }
} 