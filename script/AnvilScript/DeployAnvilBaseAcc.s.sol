// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console.sol"; 
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {AnvilHelperConfig} from "script/AnvilScript/AnvilHelperConfig.s.sol";


contract DeployAnvilBaseAcc is Script{
    BaseAccount public baseAccount;

    function run() public returns(BaseAccount,AnvilHelperConfig){
        return setUp();
    }

    function setUp() public returns(BaseAccount,AnvilHelperConfig){
        AnvilHelperConfig anvilHelperConfig = new AnvilHelperConfig();
        AnvilHelperConfig.NetworkConfig memory config = anvilHelperConfig.getAnvilConfig();

        vm.startBroadcast();
        baseAccount = new BaseAccount(config.entryPoint);
        baseAccount.transferOwnership(config.account);
        vm.stopBroadcast();

        return (baseAccount,anvilHelperConfig);
    }
}