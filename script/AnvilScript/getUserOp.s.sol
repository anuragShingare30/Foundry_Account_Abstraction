// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console.sol"; 
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {AnvilHelperConfig} from "script/AnvilScript/AnvilHelperConfig.s.sol";


contract getUserOp is Script {
    using MessageHashUtils for bytes32;

    AnvilHelperConfig public anvilHelperConfig;

    uint256 constant ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function generateSignedUserOp(
        bytes memory executionData,
        AnvilHelperConfig.NetworkConfig memory config,
        address baseAccount
    ) public returns(PackedUserOperation memory){
        uint256 nonce = vm.getNonce(baseAccount) - 1;
        PackedUserOperation memory userOp = _generateUnSignedUserOp(baseAccount, nonce, executionData);

        // get the userOpHash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // generate the signature
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v,r,s) = vm.sign(ANVIL_PRIVATE_KEY,digest);

        // AA user will sign the userOp -> Later after for verification we will use this signature
        bytes memory sig = abi.encodePacked(r,s,v);
        userOp.signature = sig;

        return userOp;
    }

    function _generateUnSignedUserOp(
        address sender,
        uint256 nonce,
        bytes memory functionData
    ) internal returns(PackedUserOperation memory){

        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender:sender,
            nonce:nonce,
            initCode:hex"",
            callData:functionData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}