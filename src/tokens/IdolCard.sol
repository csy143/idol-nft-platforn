// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IdolCard is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // 卡片类型枚举
    enum CardType { NORMAL, RARE, ULTRA_RARE }
    
    // 卡片结构
    struct Card {
        string uri;          // 元数据 URI
        CardType cardType;   // 卡片类型
        uint256 seriesId;    // 系列 ID
        uint256 mintTime;    // 铸造时间
    }
    
    // tokenId => Card
    mapping(uint256 => Card) public cards;
    
    // 系列信息
    struct Series {
        string name;         // 系列名称
        uint256 maxSupply;   // 最大发行量
        uint256 minted;      // 已铸造数量
        bool isActive;       // 是否激活
    }
    
    // seriesId => Series
    mapping(uint256 => Series) public series;
    
    constructor() ERC721("Idol Card", "IDOL") Ownable(msg.sender) {}
    
    // 创建新系列
    function createSeries(
        string memory name,
        uint256 maxSupply
    ) external onlyOwner returns (uint256) {
        uint256 seriesId = _tokenIds.current();
        series[seriesId] = Series(name, maxSupply, 0, true);
        _tokenIds.increment();
        return seriesId;
    }
    
    // 铸造新卡片
    function mint(
        address to,
        uint256 seriesId,
        string memory uri,
        CardType cardType
    ) external onlyOwner returns (uint256) {
        Series storage s = series[seriesId];
        require(s.isActive, "Series is not active");
        require(s.minted < s.maxSupply, "Series is sold out");
        
        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);
        
        cards[tokenId] = Card(uri, cardType, seriesId, block.timestamp);
        
        s.minted += 1;
        _tokenIds.increment();
        
        return tokenId;
    }
} 