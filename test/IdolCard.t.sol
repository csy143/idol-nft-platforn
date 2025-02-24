// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/IdolCard.sol";

contract IdolCardTest is Test {
    IdolCard public idolCard;
    address owner = address(1);
    address user = address(2);

    function setUp() public {
        vm.prank(owner);
        idolCard = new IdolCard();
    }

    function testCreateSeries() public {
        vm.prank(owner);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        
        (string memory name, uint256 maxSupply, uint256 minted, bool isActive) = idolCard.series(seriesId);
        assertEq(name, "TEST SERIES");
        assertEq(maxSupply, 100);
        assertEq(minted, 0);
        assertTrue(isActive);
    }

    function testMint() public {
        vm.startPrank(owner);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        uint256 tokenId = idolCard.mint(user, seriesId, "ipfs://test", IdolCard.CardType.NORMAL);
        vm.stopPrank();

        assertEq(idolCard.ownerOf(tokenId), user);
    }

    function testFailMintWhenSeriesNotActive() public {
        vm.startPrank(owner);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        
        // 创建一个不存在的系列ID
        uint256 invalidSeriesId = seriesId + 1;
        
        // 这个调用应该失败
        idolCard.mint(user, invalidSeriesId, "ipfs://test", IdolCard.CardType.NORMAL);
        vm.stopPrank();
    }

    function testFailMintWhenSeriesSoldOut() public {
        vm.startPrank(owner);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 1);
        
        // 铸造第一个 NFT
        idolCard.mint(user, seriesId, "ipfs://test1", IdolCard.CardType.NORMAL);
        
        // 尝试铸造第二个 NFT，应该失败因为 maxSupply = 1
        idolCard.mint(user, seriesId, "ipfs://test2", IdolCard.CardType.NORMAL);
        vm.stopPrank();
    }
} 