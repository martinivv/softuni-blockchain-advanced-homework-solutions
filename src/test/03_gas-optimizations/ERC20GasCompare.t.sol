// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";

import {StandardERC20} from "@/03_gas-optimizations/standard-erc20/StandardERC20.sol";
import {OptimizedERC20} from "@/03_gas-optimizations/standard-erc20/OptimizedERC20.sol";

contract ERC20GasCompareTest is Test {
    StandardERC20 public original;
    OptimizedERC20 public optimized;
    address public deployer;
    address public user1;
    address public user2;

    function setUp() public {
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        original = new StandardERC20("Test TKN", "TST", 18, 1000000 * 10 ** 18);
        optimized = new OptimizedERC20("Test TKN", "TST", 18, 1000000 * 10 ** 18);

        original.transfer(user1, 10000 * 10 ** 18);
        optimized.transfer(user1, 10000 * 10 ** 18);
    }

    function testGasCompare_Deploy() public {
        uint256 originalGasBefore = gasleft();
        new StandardERC20("Test TKN", "TST", 18, 1000000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        uint256 optimizedGasBefore = gasleft();
        new OptimizedERC20("Test TKN", "TST", 18, 1000000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        console.log("===== Gas Comparison for `deployment` =====");
        console.log("Original gas used:", originalGasUsed);
        console.log("Optimized gas used:", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved:", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase:", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=======================================");
    }

    function testGasCompare_Transfer() public {
        // 1. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        original.transfer(user2, 1000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimized.transfer(user2, 1000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 3. Compare results
        console.log("===== Gas Comparison for `transfer` =====");
        console.log("Original gas used:", originalGasUsed);
        console.log("Optimized gas used:", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved:", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase:", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=======================================");
    }

    function testGasCompare_Approve() public {
        // 1. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        original.approve(user2, 1000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimized.approve(user2, 1000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 3. Compare results
        console.log("===== Gas Comparison for `approve` =====");
        console.log("Original gas used:", originalGasUsed);
        console.log("Optimized gas used:", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved:", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase:", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("======================================");
    }

    function testGasCompare_TransferFrom() public {
        // 1. First approve for both contracts
        vm.startPrank(user1);
        original.approve(address(this), 5000 * 10 ** 18);
        optimized.approve(address(this), 5000 * 10 ** 18);
        vm.stopPrank();

        // 2. Test original contract
        uint256 originalGasBefore = gasleft();
        original.transferFrom(user1, user2, 1000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 3. Test optimized contract
        uint256 optimizedGasBefore = gasleft();
        optimized.transferFrom(user1, user2, 1000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("===== Gas Comparison for `transferFrom` =====");
        console.log("Original gas used:", originalGasUsed);
        console.log("Optimized gas used:", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved:", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase:", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("==========================================");
    }
}
