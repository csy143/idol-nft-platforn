// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/access/CompanyRegistry.sol";
import "../src/tokens/IdolCard.sol";
import "../src/market/IdolMarket.sol";
import "../src/market/IdolAuction.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CompanyRegistry companyRegistry = new CompanyRegistry();
        IdolCard idolCard = new IdolCard(address(companyRegistry));
        IdolMarket idolMarket = new IdolMarket(address(idolCard));
        IdolAuction idolAuction = new IdolAuction(address(idolCard));

        vm.stopBroadcast();

        console.log("CompanyRegistry deployed at:", address(companyRegistry));
        console.log("IdolCard deployed at:", address(idolCard));
        console.log("IdolMarket deployed at:", address(idolMarket));
        console.log("IdolAuction deployed at:", address(idolAuction));
    }
}