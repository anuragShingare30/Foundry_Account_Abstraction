// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test,console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {BaseAccount} from "src/ethereum/BaseAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployBaseAcc} from "script/DeployBaseAcc.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract BaseaccountTest is Test{

    HelperConfig public helperConfig;
    BaseAccount public baseAccount;
    ERC20Mock public usdc;

    address user = makeAddr("user");
    uint256 AMOUNT = 1e18;

    function setUp() public {
        DeployBaseAcc deployBaseAcc = new DeployBaseAcc();
        (baseAccount,helperConfig) = deployBaseAcc.run();
        usdc = new ERC20Mock();
    }

    function test_OwnerCanExecute() public {
        assert(usdc.balanceOf(address(baseAccount)) == 0);
        address to = address(usdc);
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(baseAccount),AMOUNT);
        vm.startPrank(baseAccount.owner());
        baseAccount.execute(to, AMOUNT, data,1000);
        vm.stopPrank();

        assert(usdc.balanceOf(address(baseAccount)) == AMOUNT);
    }
}