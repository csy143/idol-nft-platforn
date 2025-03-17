// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/access/CompanyRegistry.sol";

contract CompanyRegistryTest is Test {
    CompanyRegistry public registry;
    
    address owner = address(1);
    address company = address(2);
    address admin = address(3);
    address newAdmin = address(4);
    
    function setUp() public {
        vm.prank(owner);
        registry = new CompanyRegistry();
    }
    
    function testRegisterCompany() public {
        vm.prank(owner);
        registry.registerCompany(company, "Test Company", admin);
        
        (string memory name, address adminAddr, bool isActive,) = registry.getCompanyDetails(company);
        assertEq(name, "Test Company");
        assertEq(adminAddr, admin);
        assertTrue(isActive);
    }
    
    function test_RevertWhen_RegisterDuplicate() public {
        vm.startPrank(owner);
        registry.registerCompany(company, "Test Company", admin);
        
        vm.expectRevert("Company already registered");
        registry.registerCompany(company, "Test Company 2", admin);
        vm.stopPrank();
    }
    
    function testDeactivateCompany() public {
        vm.startPrank(owner);
        registry.registerCompany(company, "Test Company", admin);
        registry.deactivateCompany(company);
        vm.stopPrank();
        
        (,, bool isActive,) = registry.getCompanyDetails(company);
        assertFalse(isActive);
    }
    
    function testReactivateCompany() public {
        vm.startPrank(owner);
        registry.registerCompany(company, "Test Company", admin);
        registry.deactivateCompany(company);
        registry.reactivateCompany(company);
        vm.stopPrank();
        
        (,, bool isActive,) = registry.getCompanyDetails(company);
        assertTrue(isActive);
    }
    
    function testUpdateCompanyAdmin() public {
        // 所有者可以更新管理员
        vm.prank(owner);
        registry.registerCompany(company, "Test Company", admin);
        
        vm.prank(owner);
        registry.updateCompanyAdmin(company, newAdmin);
        
        (,address adminAddr,,) = registry.getCompanyDetails(company);
        assertEq(adminAddr, newAdmin);
        
        // 当前管理员也可以更新
        vm.prank(newAdmin);
        registry.updateCompanyAdmin(company, admin);
        
        (,adminAddr,,) = registry.getCompanyDetails(company);
        assertEq(adminAddr, admin);
    }
    
    function test_RevertWhen_UnauthorizedUpdate() public {
        vm.prank(owner);
        registry.registerCompany(company, "Test Company", admin);
        
        vm.prank(address(5)); // 未授权地址
        vm.expectRevert("Not authorized");
        registry.updateCompanyAdmin(company, newAdmin);
    }
} 