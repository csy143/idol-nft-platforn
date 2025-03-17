// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/IdolCard.sol";
import "../src/access/CompanyRegistry.sol";

contract IdolCardTest is Test {
    IdolCard public idolCard;
    CompanyRegistry public registry;
    
    address owner = address(1);
    address company = address(2);
    address user = address(3);
    
    function setUp() public {
        vm.startPrank(owner);
        // 部署合约
        registry = new CompanyRegistry();
        idolCard = new IdolCard(address(registry));
        
        // 注册经纪公司
        registry.registerCompany(company, "Test Company", company);
        vm.stopPrank();
    }
    
    function testCreateSeries() public {
        vm.prank(company);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        
        (string memory name, uint256 maxSupply, uint256 minted, bool isActive, address seriesCompany) = idolCard.series(seriesId);
        assertEq(name, "TEST SERIES");
        assertEq(maxSupply, 100);
        assertEq(minted, 0);
        assertTrue(isActive);
        assertEq(seriesCompany, company);
    }
    
    function test_RevertWhen_UnauthorizedCompany() public {
        vm.prank(user); // 未注册的公司
        vm.expectRevert("Not an active company");
        idolCard.createSeries("TEST SERIES", 100);
    }
    
    function testMint() public {
        vm.startPrank(company);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        uint256 tokenId = idolCard.mint(user, seriesId, "ipfs://test", IdolCard.CardType.NORMAL);
        vm.stopPrank();
        
        assertEq(idolCard.ownerOf(tokenId), user);
        
        (,,,, address cardCompany) = idolCard.getCardDetails(tokenId);
        assertEq(cardCompany, company);
    }
    
    function test_RevertWhen_WrongCompanyMint() public {
        vm.prank(company);
        uint256 seriesId = idolCard.createSeries("TEST SERIES", 100);
        
        address wrongCompany = address(4);
        vm.prank(owner);
        registry.registerCompany(wrongCompany, "Wrong Company", wrongCompany);
        
        vm.prank(wrongCompany);
        vm.expectRevert("Not series company");
        idolCard.mint(user, seriesId, "ipfs://test", IdolCard.CardType.NORMAL);
    }
} 