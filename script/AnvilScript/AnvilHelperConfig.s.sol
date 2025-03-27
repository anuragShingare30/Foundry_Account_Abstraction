// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console.sol"; 
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";


contract AnvilHelperConfig is Script{
    struct NetworkConfig {
        address entryPoint;
        address usdc;
        address account;
    }

    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // deploy mocks
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        ERC20Mock erc20Mock = new ERC20Mock();
        vm.stopBroadcast();

        return NetworkConfig({
            entryPoint: address(entryPoint), 
            usdc: address(erc20Mock), 
            account: ANVIL_DEFAULT_ACCOUNT
            });
    }
}