// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/market/IdolAuction.sol";
import "../src/tokens/IdolCard.sol";
import "../src/access/CompanyRegistry.sol";

contract IdolAuctionTest is Test {
    IdolAuction public auction;
    IdolCard public idolCard;
    CompanyRegistry public registry;
    
    address owner = address(1);
    address company = address(2);
    address seller = address(3);
    address bidder1 = address(4);
    address bidder2 = address(5);
    
    uint256 tokenId;
    uint256 startingPrice = 1 ether;
    uint256 minIncrement = 0.1 ether;
    uint256 duration = 1 days;
    
    function setUp() public {
        vm.startPrank(owner);
        // 部署合约
        registry = new CompanyRegistry();
        idolCard = new IdolCard(address(registry));
        auction = new IdolAuction(address(idolCard));
        
        // 注册公司并创建系列
        registry.registerCompany(company, "Test Company", company);
        vm.stopPrank();
        
        // 铸造NFT给卖家
        vm.startPrank(company);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        tokenId = idolCard.mint(seller, seriesId, "ipfs://test", IdolCard.CardType.RARE);
        vm.stopPrank();
    }
    
    function testCreateAuction() public {
        vm.startPrank(seller);
        idolCard.approve(address(auction), tokenId);
        auction.createAuction(tokenId, startingPrice, minIncrement, duration);
        vm.stopPrank();
        
        (
            address auctionSeller,
            uint256 auctionStartingPrice,
            uint256 auctionMinIncrement,
            uint256 startTime,
            uint256 endTime,
            ,
            ,
            bool ended
        ) = auction.auctions(tokenId);
        
        assertEq(auctionSeller, seller);
        assertEq(auctionStartingPrice, startingPrice);
        assertEq(auctionMinIncrement, minIncrement);
        assertEq(endTime - startTime, duration);
        assertFalse(ended);
    }
    
    function testPlaceBid() public {
        // 创建拍卖
        vm.prank(seller);
        idolCard.approve(address(auction), tokenId);
        vm.prank(seller);
        auction.createAuction(tokenId, startingPrice, minIncrement, duration);
        
        // 出价
        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        auction.placeBid{value: 1.5 ether}(tokenId);
        
        (address highestBidder, uint256 highestBid) = auction.getHighestBid(tokenId);
        assertEq(highestBidder, bidder1);
        assertEq(highestBid, 1.5 ether);
    }
    
    function testEndAuction() public {
        // 创建拍卖
        vm.prank(seller);
        idolCard.approve(address(auction), tokenId);
        vm.prank(seller);
        auction.createAuction(tokenId, startingPrice, minIncrement, duration);
        
        // 出价
        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        auction.placeBid{value: 1.5 ether}(tokenId);
        
        // 时间快进
        vm.warp(block.timestamp + duration + 1);
        
        // 结束拍卖
        auction.endAuction(tokenId);
        
        // 验证NFT所有权转移
        assertEq(idolCard.ownerOf(tokenId), bidder1);
    }

    function test_RevertWhen_InvalidDuration() public {
        vm.startPrank(seller);
        idolCard.approve(address(auction), tokenId);
        
        // 测试太短的持续时间
        vm.expectRevert("Duration too short");
        auction.createAuction(tokenId, startingPrice, minIncrement, 30 minutes);
        
        // 测试太长的持续时间
        vm.expectRevert("Duration too long");
        auction.createAuction(tokenId, startingPrice, minIncrement, 8 days);
        vm.stopPrank();
    }

    function testMultipleBids() public {
        // 创建拍卖
        vm.prank(seller);
        idolCard.approve(address(auction), tokenId);
        vm.prank(seller);
        auction.createAuction(tokenId, startingPrice, minIncrement, duration);
        
        // 第一个出价
        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        auction.placeBid{value: 1.2 ether}(tokenId);
        
        // 第二个出价
        vm.deal(bidder2, 2 ether);
        vm.prank(bidder2);
        auction.placeBid{value: 1.5 ether}(tokenId);
        
        // 验证最高出价
        (address highestBidder, uint256 highestBid) = auction.getHighestBid(tokenId);
        assertEq(highestBidder, bidder2);
        assertEq(highestBid, 1.5 ether);
    }

    function testWithdrawBid() public {
        // 创建拍卖
        vm.prank(seller);
        idolCard.approve(address(auction), tokenId);
        vm.prank(seller);
        auction.createAuction(tokenId, startingPrice, minIncrement, duration);
        
        // 两个人出价
        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        auction.placeBid{value: 1.2 ether}(tokenId);
        
        vm.deal(bidder2, 2 ether);
        vm.prank(bidder2);
        auction.placeBid{value: 1.5 ether}(tokenId);
        
        // 结束拍卖
        vm.warp(block.timestamp + duration + 1);
        auction.endAuction(tokenId);
        
        // 记录未中标者的初始余额
        uint256 initialBalance = bidder1.balance;
        
        // 未中标者提取出价
        vm.prank(bidder1);
        auction.withdrawBid(tokenId);
        
        // 验证余额变化
        assertEq(bidder1.balance - initialBalance, 1.2 ether);
    }

    function test_RevertWhen_WinnerWithdraw() public {
        // 创建拍卖
        vm.prank(seller);
        idolCard.approve(address(auction), tokenId);
        vm.prank(seller);
        auction.createAuction(tokenId, startingPrice, minIncrement, duration);
        
        // 出价
        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        auction.placeBid{value: 1.5 ether}(tokenId);
        
        // 结束拍卖
        vm.warp(block.timestamp + duration + 1);
        auction.endAuction(tokenId);
        
        // 中标者尝试提取出价（应该失败）
        vm.prank(bidder1);
        vm.expectRevert("Winner cannot withdraw");
        auction.withdrawBid(tokenId);
    }
} 