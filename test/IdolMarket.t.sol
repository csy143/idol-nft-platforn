// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/market/IdolMarket.sol";
import "../src/tokens/IdolCard.sol";
import "../src/access/CompanyRegistry.sol";


contract IdolMarketTest is Test {
    IdolCard public idolCard;
    IdolMarket public market;
    CompanyRegistry public registry;
    
    address owner = address(1);
    address seller = address(2);
    address buyer = address(3);
    
    uint256 listingPrice = 1 ether;
    
    function setUp() public {
        vm.startPrank(owner);
        registry = new CompanyRegistry();
        idolCard = new IdolCard(address(registry));
        market = new IdolMarket(address(idolCard));
        registry.registerCompany(seller, "Test Company", seller);
        vm.stopPrank();
        
        // 给卖家铸造一个NFT
        vm.startPrank(seller);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        idolCard.mint(seller, seriesId, "ipfs://test", IdolCard.CardType.NORMAL);
        vm.stopPrank();
    }
    
    function testListToken() public {
        vm.startPrank(seller);
        idolCard.approve(address(market), 0);
        market.listToken(0, listingPrice);
        vm.stopPrank();
        
        (address listedSeller, uint256 price, bool isActive) = market.listings(0);
        assertEq(listedSeller, seller);
        assertEq(price, listingPrice);
        assertTrue(isActive);
    }
    
    function testBuyToken() public {
        // 上架
        vm.startPrank(seller);
        idolCard.approve(address(market), 0);
        market.listToken(0, listingPrice);
        vm.stopPrank();
        
        // 购买
        vm.deal(buyer, 2 ether); // 给买家一些ETH
        vm.prank(buyer);
        market.buyToken{value: listingPrice}(0);
        
        assertEq(idolCard.ownerOf(0), buyer);
    }
} 