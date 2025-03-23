// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console.sol"; 
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";


contract HelperConfig is Script{
    // error
    error HelperConfig_InvalidChainId();
    
    // types
    struct NetworkConfig{
        address entryPoint;
        address usdc;
        address account;
    }
    mapping (uint256 chainId => NetworkConfig) public chainConfig;

    // State variables
    NetworkConfig public localNetworkConfig;
    uint256 private constant ETH_MAINNET_CHAINID = 1;
    uint256 private constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 private constant ZKSYNC_SEPOLIA_CHAINID = 300;
    uint256 private constant ZKSYNC_CHAINID = 324;
    uint256 private constant ARB_MAINNET_CHAINID = 42161;
    uint256 private constant ANVIL_CHAINID = 31337;
    address private constant BURNER_WALLET = 0xECe6dcc60bBDfE74a67CB26b1B83af791Aa22AE6;
    address private constant ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;


    // FUNCTIONS
    constructor() {
        chainConfig[ETH_MAINNET_CHAINID] = getEthMainConfig();
        chainConfig[ETH_SEPOLIA_CHAINID] = getEthSepoliaConfig();
        chainConfig[ZKSYNC_SEPOLIA_CHAINID] = getZKSyncSepConfig();
        chainConfig[ZKSYNC_CHAINID] = getZKSync();
        chainConfig[ARB_MAINNET_CHAINID] = getArbMainConfig();
        chainConfig[ANVIL_CHAINID] = getAnvilConfig();
    }


    function getConfig() public returns(NetworkConfig memory){
        return getChainConfig(block.chainid);
    }

    function getChainConfig(uint256 chainId) public returns(NetworkConfig memory){
        if(chainId == ANVIL_CHAINID){
            return getAnvilConfig();
        }else if(chainConfig[chainId].account != address(0)){
            return chainConfig[chainId];
        }else{
            revert HelperConfig_InvalidChainId();
        }
    }

    function getEthMainConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            account:BURNER_WALLET
        });
    }
    function getEthSepoliaConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            usdc: 0x53844F9577C2334e541Aec7Df7174ECe5dF1fCf0,
            account:BURNER_WALLET
        });
    }
    function getZKSyncSepConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            entryPoint: address(0),
            usdc: 0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4,
            account:BURNER_WALLET
        });
    }
    function getZKSync() public view returns(NetworkConfig memory){
        return NetworkConfig({
            entryPoint: address(0),
            usdc: 0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E,
            account:BURNER_WALLET
        });
    }
    function getArbMainConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            account:BURNER_WALLET
        });
    }

    function getAnvilConfig() public returns(NetworkConfig memory){
         if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }


        vm.startBroadcast(ANVIL_ADDRESS);
        EntryPoint _entryPoint = new EntryPoint();
        ERC20Mock _erc20Mock = new ERC20Mock();
        vm.stopBroadcast();
        return NetworkConfig({
            entryPoint:address(_entryPoint),
            usdc: address(_erc20Mock),
            account: ANVIL_ADDRESS
        });
    }


}