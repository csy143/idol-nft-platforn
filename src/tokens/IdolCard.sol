// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../access/CompanyRegistry.sol";

contract IdolCard is ERC721, Ownable {
    uint256 private _nextTokenId; // 用于追踪下一个 tokenId
    uint256 private _nextSeriesId; // 用于追踪下一个 seriesId
    
    CompanyRegistry public companyRegistry;
    
    // 卡片类型枚举
    enum CardType { NORMAL, RARE, ULTRA_RARE }
    
    // 卡片结构
    struct Card {
        string uri;          // 元数据 URI
        CardType cardType;   // 卡片类型
        uint256 seriesId;    // 系列 ID
        uint256 mintTime;    // 铸造时间
        address company;     // 发行公司
    }
    
    // 系列结构
    struct Series {
        string name;         // 系列名称
        uint256 maxSupply;   // 最大发行量
        uint256 minted;      // 已铸造数量
        bool isActive;       // 是否激活
        address company;     // 发行公司
    }
    
    // tokenId => Card
    mapping(uint256 => Card) public cards;
    // seriesId => Series
    mapping(uint256 => Series) public series;
    
    event SeriesCreated(uint256 indexed seriesId, string name, address indexed company);
    event CardMinted(uint256 indexed tokenId, uint256 indexed seriesId, address indexed company);
    
    constructor(address _companyRegistry) ERC721("Idol Card", "IDOL") Ownable(msg.sender) {
        companyRegistry = CompanyRegistry(_companyRegistry);
    }
    
    // 修改器：检查是否为活跃的经纪公司
    modifier onlyActiveCompany() {
        require(companyRegistry.isActiveCompany(msg.sender), "Not an active company");
        _;
    }
    
    // 修改器：检查是否为系列发行公司
    modifier onlySeriesCompany(uint256 seriesId) {
        require(series[seriesId].company == msg.sender, "Not series company");
        _;
    }
    
    // 创建新系列（只有活跃的经纪公司可以创建）
    function createSeries(
        string memory name,
        uint256 maxSupply
    ) external onlyActiveCompany returns (uint256) {
        uint256 seriesId = _nextSeriesId++;
        
        series[seriesId] = Series({
            name: name,
            maxSupply: maxSupply,
            minted: 0,
            isActive: true,
            company: msg.sender
        });
        
        emit SeriesCreated(seriesId, name, msg.sender);
        return seriesId;
    }
    
    // 铸造新卡片（只有系列发行公司可以铸造）
    function mint(
        address to,
        uint256 seriesId,
        string memory uri,
        CardType cardType
    ) external onlySeriesCompany(seriesId) returns (uint256) {
        Series storage s = series[seriesId];
        require(s.isActive, "Series is not active");
        require(s.minted < s.maxSupply, "Series is sold out");
        
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        
        cards[tokenId] = Card({
            uri: uri,
            cardType: cardType,
            seriesId: seriesId,
            mintTime: block.timestamp,
            company: msg.sender
        });
        
        s.minted += 1;
        
        emit CardMinted(tokenId, seriesId, msg.sender);
        return tokenId;
    }
    
    // 获取卡片详细信息
    function getCardDetails(uint256 tokenId)
        external
        view
        returns (
            string memory uri,
            CardType cardType,
            uint256 seriesId,
            uint256 mintTime,
            address company
        )
    {
        Card storage card = cards[tokenId];
        return (
            card.uri,
            card.cardType,
            card.seriesId,
            card.mintTime,
            card.company
        );
    }
    
    // 更新公司注册表地址（仅所有者）
    function updateCompanyRegistry(address _companyRegistry) external onlyOwner {
        require(_companyRegistry != address(0), "Invalid registry address");
        companyRegistry = CompanyRegistry(_companyRegistry);
    }
} 