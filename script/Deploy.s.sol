// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/IdolCard.sol";

contract DeployScript is Script {
    function run() external {
        // 获取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始部署
        vm.startBroadcast(deployerPrivateKey);

        // 部署 IdolCard 合约
        IdolCard idolCard = new IdolCard();

        // 创建测试系列
        idolCard.createSeries("First Series", 1000);

        vm.stopBroadcast();
    }
} 