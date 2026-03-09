// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {EvictionVault} from "../src/EvictionVault.sol";
import {EvictionVaultAccessControl} from "../src/EvictionVaultAccessControl.sol";

contract DeployEvictionVault is Script {
    function run() external {
 
        vm.startBroadcast();

        // Admin account for roles
        address admin = msg.sender;

       
        address ;
        owners[0] = 0x1234567890123456789012345678901234567890; // Replace with actual owner1
        owners[1] = 0x0987654321098765432109876543210987654321; // Replace with actual owner2

        // Deploy AccessControl (optional if embedded in EvictionVault)
        EvictionVaultAccessControl accessControl = new EvictionVaultAccessControl(admin);
        console.log("AccessControl deployed at:", address(accessControl));

 
        EvictionVault vault = (new EvictionVault){value: 1 ether}(owners, 2, admin);
        console.log("EvictionVault deployed at:", address(vault));

        vm.stopBroadcast();
    }
}