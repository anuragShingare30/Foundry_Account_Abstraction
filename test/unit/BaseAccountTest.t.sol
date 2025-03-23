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

contract BaseaccountTest is Test{
    // errors
    error BaseAccount_CallFailedDuringExecute();

    HelperConfig public helperConfig;
    BaseAccount public baseAccount;
    ERC20Mock public usdc;
    PackedUserOp public packedUserOp;

    address public user = makeAddr("user");
    uint256 public AMOUNT = 1e18;

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

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(baseAccount),AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(BaseAccount.execute.selector, address(usdc), 0, functionData);


        PackedUserOperation memory packedUserOperation = 
            packedUserOp.generateSignedUserOp(executeCallData, helperConfig.getConfig()); //1

       bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOperation); //2

        bytes memory signature = packedUserOperation.signature;
        address actualSigner = ECDSA.recover(userOpHash, signature);

        assert(actualSigner == baseAccount.owner());
    }

}