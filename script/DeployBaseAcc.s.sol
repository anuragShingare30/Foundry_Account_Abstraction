// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console.sol"; 
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployBaseAcc is Script {
    BaseAccount public baseAccount;

    function setUp() public returns(BaseAccount baseAccount,HelperConfig helperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        vm.startBroadcast(networkConfig.account);
        baseAccount = new BaseAccount(networkConfig.entryPoint);
        baseAccount.transferOwnership(networkConfig.account);
        vm.stopBroadcast();
    }

    function run() public returns(BaseAccount,HelperConfig) {
        return setUp();
    }
}