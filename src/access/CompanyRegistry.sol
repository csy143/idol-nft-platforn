// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CompanyRegistry is Ownable {
    // 经纪公司结构
    struct Company {
        string name;            // 公司名称
        address adminAddress;   // 管理员地址
        bool isActive;         // 是否激活
        uint256 registerTime;  // 注册时间
    }
    
    // 经纪公司映射
    mapping(address => Company) public companies;
    
    // 已注册的经纪公司地址数组
    address[] public companyList;
    
    // 事件
    event CompanyRegistered(address indexed companyAddress, string name, address adminAddress);
    event CompanyDeactivated(address indexed companyAddress);
    event CompanyReactivated(address indexed companyAddress);
    event CompanyAdminUpdated(address indexed companyAddress, address newAdmin);
    
    constructor() Ownable(msg.sender) {}
    
    // 注册新经纪公司
    function registerCompany(
        address companyAddress,
        string memory name,
        address adminAddress
    ) external onlyOwner {
        require(companyAddress != address(0), "Invalid company address");
        require(adminAddress != address(0), "Invalid admin address");
        require(companies[companyAddress].adminAddress == address(0), "Company already registered");
        
        companies[companyAddress] = Company({
            name: name,
            adminAddress: adminAddress,
            isActive: true,
            registerTime: block.timestamp
        });
        
        companyList.push(companyAddress);
        
        emit CompanyRegistered(companyAddress, name, adminAddress);
    }
    
    // 停用经纪公司
    function deactivateCompany(address companyAddress) external onlyOwner {
        require(companies[companyAddress].adminAddress != address(0), "Company not registered");
        require(companies[companyAddress].isActive, "Company already deactivated");
        
        companies[companyAddress].isActive = false;
        
        emit CompanyDeactivated(companyAddress);
    }
    
    // 重新激活经纪公司
    function reactivateCompany(address companyAddress) external onlyOwner {
        require(companies[companyAddress].adminAddress != address(0), "Company not registered");
        require(!companies[companyAddress].isActive, "Company already active");
        
        companies[companyAddress].isActive = true;
        
        emit CompanyReactivated(companyAddress);
    }
    
    // 更新经纪公司管理员
    function updateCompanyAdmin(address companyAddress, address newAdmin) external {
        require(newAdmin != address(0), "Invalid admin address");
        require(
            msg.sender == owner() || msg.sender == companies[companyAddress].adminAddress,
            "Not authorized"
        );
        
        companies[companyAddress].adminAddress = newAdmin;
        
        emit CompanyAdminUpdated(companyAddress, newAdmin);
    }
    
    // 检查地址是否为活跃的经纪公司
    function isActiveCompany(address companyAddress) external view returns (bool) {
        return companies[companyAddress].isActive;
    }
    
    // 获取经纪公司数量
    function getCompanyCount() external view returns (uint256) {
        return companyList.length;
    }
    
    // 获取经纪公司详情
    function getCompanyDetails(address companyAddress)
        external
        view
        returns (
            string memory name,
            address adminAddress,
            bool isActive,
            uint256 registerTime
        )
    {
        Company storage company = companies[companyAddress];
        return (
            company.name,
            company.adminAddress,
            company.isActive,
            company.registerTime
        );
    }
} 