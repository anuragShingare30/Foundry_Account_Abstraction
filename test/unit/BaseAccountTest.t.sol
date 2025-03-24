// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test,console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployBaseAcc} from "script/DeployBaseAcc.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOp} from "script/PackedUserOp.s.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";



contract BaseaccountTest is Test{
    using MessageHashUtils for bytes32;

    // errors
    error BaseAccount_CallFailedDuringExecute();

    HelperConfig public helperConfig;
    BaseAccount public baseAccount;
    ERC20Mock public usdc;
    PackedUserOp public packedUserOp;

    address public user = makeAddr("user");
    uint256 public AMOUNT = 1e18;
    uint256 public ANVIL_CHAINID = 31337;

    function setUp() public {
        DeployBaseAcc deployBaseAcc = new DeployBaseAcc();
        (baseAccount,helperConfig) = deployBaseAcc.run();
        usdc = new ERC20Mock();
        packedUserOp = new PackedUserOp();
        vm.deal(address(baseAccount), 2e18);
    }

    /**
     * test_OwnerCanExecute TEST FUCNTION
     * By traditional metamask account == baseAccount.sol
     * @dev baseAccount.sol will interact/send TNX to other DApps -> same as like by metamask account
     
     * @notice Owner(user) init. execute() -> baseAccount will interact with USDC contract
     * @dev Now, baseAccount.sol is my new account which will interact with DApps without need of any fancy and confusing TNX process (just like any metamask TNX!!! )
     */
    function test_OwnerCanExecute() public {
        assert(usdc.balanceOf(address(baseAccount)) == 0);

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(baseAccount),AMOUNT);
        vm.startPrank(baseAccount.owner());
        baseAccount.execute(address(usdc), 0, functionData);
        vm.stopPrank();

        assert(usdc.balanceOf(address(baseAccount)) == AMOUNT);
    }

    function test_OwnerExecuteWithWrongFunctionData() public {
        assert(usdc.balanceOf(address(baseAccount)) == 0);

        bytes memory functionData = "";
        vm.startPrank(baseAccount.owner());
        vm.expectRevert();
        baseAccount.execute(address(usdc), 0, functionData);
        vm.stopPrank();
    }
    function test_NonOwnerCannotExecute() public {
        assert(usdc.balanceOf(address(baseAccount)) == 0);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(baseAccount),AMOUNT);
        vm.startPrank(user);
        vm.expectRevert(BaseAccount.BasicAccount_NotFromEntryPointOrOwner.selector);
        baseAccount.execute(address(usdc), 0, functionData);
        vm.stopPrank();
    }


    function test_SigPackedUserOp() public {
        assert(usdc.balanceOf(address(baseAccount)) == 0);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(baseAccount),AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(BaseAccount.execute.selector, address(usdc), 0, functionData);

        PackedUserOperation memory packedUserOperation = 
            packedUserOp.generateSignedUserOp(executeCallData, config,address(baseAccount)); //1

       bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOperation); //2

        bytes memory signature = packedUserOperation.signature;
        address actualSigner = ECDSA.recover(userOpHash.toEthSignedMessageHash(), signature);

        assert(actualSigner == baseAccount.owner());
    }


    function test_helperConfig() public {
        vm.startPrank(baseAccount.owner());
        address sender = helperConfig.getConfig().account;
        vm.stopPrank();
        assert(sender == 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }


    // sign userOp
    // pass the userOp to bundlers
    // bundlers will call entryPoint contract
    // baseAccount will call validateUserOp function to check validation
    function test_validateUserOp() public {
        // Arrange
        assert(usdc.balanceOf(address(baseAccount)) == 0);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(baseAccount),AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(BaseAccount.execute.selector, address(usdc), 0, functionData);

        PackedUserOperation memory userOp = 
            packedUserOp.generateSignedUserOp(executeCallData, config,address(baseAccount)); //1

       bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp); //2
       uint256 missingAccountFunds = 1e18;
    //    Act
       vm.startPrank(config.entryPoint);
       uint256 success = baseAccount.validateUserOp(userOp, userOpHash, missingAccountFunds);
       vm.stopPrank();

    //    Assert
    assert(success == 0);
    }


    function test_entryPointCanExecuteFunctions() public {
        // Arrange
        assert(usdc.balanceOf(address(baseAccount)) == 0);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(baseAccount),AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(BaseAccount.execute.selector, address(usdc), 0, functionData);

        PackedUserOperation memory userOp = 
            packedUserOp.generateSignedUserOp(executeCallData, config,address(baseAccount)); //1

        // Act
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.startPrank(user);
        IEntryPoint(config.entryPoint).handleOps(ops, payable(user));
        vm.stopPrank();

        assert(usdc.balanceOf(address(baseAccount)) == AMOUNT);
    }
}