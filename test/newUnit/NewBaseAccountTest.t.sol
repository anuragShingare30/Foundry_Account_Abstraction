// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test,console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOp} from "script/PackedUserOp.s.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {AnvilHelperConfig} from "script/AnvilScript/AnvilHelperConfig.s.sol";
import {DeployAnvilBaseAcc} from "script/AnvilScript/DeployAnvilBaseAcc.s.sol";
import {getUserOp} from "script/AnvilScript/getUserOp.s.sol";


/**
    @notice NewBaseAccountTest Test contract

    @dev This test is fully for anvil
 */

contract NewBaseAccountTest is Test {
    using MessageHashUtils for bytes32;

    BaseAccount public baseAccount;
    AnvilHelperConfig public anvilConfig;
    ERC20Mock public usdc;
    getUserOp public getuserop;

    address public user = makeAddr("user");
    uint256 public AMOUNT = 1e18;
    uint256 public ANVIL_CHAINID = 31337;


    function setUp() public {
        DeployAnvilBaseAcc deploy = new DeployAnvilBaseAcc();
        (baseAccount,anvilConfig) = deploy.run();
        usdc = new ERC20Mock();
        getuserop = new getUserOp();
        vm.deal(address(baseAccount),AMOUNT);
    }

    // baseAccount -> validateUserOps(userOp, userOpHash,missingAccfunds)
    // EntryPoint  -> getUserOpHash(userOp), handleOps(ops[], beneficiaryAddress)
    // getUserOp -> generateSignedUserOp(executionData,config,baseAccount)
    // signature verification -> ECDSA -> recover(userOpHash, userOps_Signature)


    function test_executeFunction() public {
        assert(usdc.balanceOf(address(baseAccount)) == 0);

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(baseAccount), AMOUNT);
        vm.startPrank(baseAccount.owner());
        baseAccount.execute(address(usdc), 0, functionData);
        vm.stopPrank();

        assert(usdc.balanceOf(address(baseAccount)) == AMOUNT);
    }

    function test_RevertsIf_NonOwnerExecuteFunction() public {
        assert(usdc.balanceOf(address(baseAccount)) == 0);

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(baseAccount), AMOUNT);
        vm.startPrank(user);
        vm.expectRevert(BaseAccount.BasicAccount_NotFromEntryPointOrOwner.selector);
        baseAccount.execute(address(usdc), 0, functionData);
        vm.stopPrank();
    }


    function test_entryPointVerifiesSignature() public {

        AnvilHelperConfig.NetworkConfig memory config = anvilConfig.getAnvilConfig();

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(baseAccount), AMOUNT);
        bytes memory executionData = abi.encodeWithSelector(baseAccount.execute.selector, address(usdc),0,functionData);

        PackedUserOperation memory userOps = getuserop.generateSignedUserOp(executionData, config , address(baseAccount));

        // get the actual userOps signer from userOpHash -> ECDSA
        bytes memory signature = userOps.signature;
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOps);

        address userOpsSigner = ECDSA.recover(userOpHash.toEthSignedMessageHash(),signature);
        console.log("userOpSigner address:", userOpsSigner);
        console.log("AA user who signed the userOps:", baseAccount.owner());

        assert(userOpsSigner == baseAccount.owner());
    }

}