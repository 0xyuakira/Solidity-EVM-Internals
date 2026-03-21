// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/runtime_execution_context/01_enter_root_frame_env_binding/RootFrameEnvBinding.sol";

/// @title RootFrameEnvBindingTest
/// @notice Verify environment binding semantics at root call frame entry
contract RootFrameEnvBindingTest is Test {
    RootFrameEnvBinding rootFrameEnvBinding;
    address internal constant EOA = address(0xA11CE);
    uint256 internal constant TEST_GAS_PRICE = 7 gwei;
    uint256 internal constant TEST_BASEFEE = 1 gwei;
    uint256 internal constant TEST_BLOCK_NUMBER = 1_234_567;
    uint256 internal constant TEST_BLOCK_TIMESTAMP = 1_700_000_000;

    /// @notice Deploy PoC contracts before each test
    function setUp() public {
        rootFrameEnvBinding = new RootFrameEnvBinding();
        vm.deal(EOA, 100 ether);
        vm.txGasPrice(TEST_GAS_PRICE);
        vm.fee(TEST_BASEFEE);
        vm.roll(TEST_BLOCK_NUMBER);
        vm.warp(TEST_BLOCK_TIMESTAMP);
    }

    /// @notice Root-frame observation: direct call enters target frame once
    function test_root_frame_env_bootstrap() public {
        // ==== Input ====
        bytes memory payload = hex"112233445566";
        uint256 callValue = 1 ether;

        // ==== Execute ====
        vm.prank(EOA, EOA);
        RootFrameEnvBinding.EnvSnapshot memory env = rootFrameEnvBinding.snapshot{value: callValue}(payload);
        bytes memory expectedData = abi.encodeCall(rootFrameEnvBinding.snapshot, (payload));

        // ==== Assert frame-level bindings ====
        assertEq(env.callFrame.self, address(rootFrameEnvBinding));
        assertEq(env.callFrame.sender, EOA);
        assertEq(env.callFrame.value, callValue);
        assertEq(env.callFrame.sig, rootFrameEnvBinding.snapshot.selector);
        assertEq(env.callFrame.dataLength, expectedData.length);
        assertEq(env.callFrame.dataHash, keccak256(expectedData));

        // ==== Assert transaction-level bindings ====
        assertEq(env.transaction.txOrigin, EOA);
        assertEq(env.transaction.txGasPrice, TEST_GAS_PRICE);

        // ==== Assert block-level bindings ====
        assertEq(env.blockCtx.blockNumber, TEST_BLOCK_NUMBER);
        assertEq(env.blockCtx.blockTimestamp, TEST_BLOCK_TIMESTAMP);
        assertEq(env.blockCtx.blockBasefee, TEST_BASEFEE);
        assertEq(env.blockCtx.chainId, block.chainid);
    }

    /// @notice Same-frame stability: internal call does not change environment bindings
    function test_same_frame_binding_stability_with_internal_call() public {
        // ==== Input ====
        bytes memory payload = hex"1122aabbccdd";
        uint256 callValue = 0.5 ether;

        // ==== Execute with one internal call between two captures ====
        vm.prank(EOA, EOA);
        (
            RootFrameEnvBinding.EnvSnapshot memory beforeInternal,
            RootFrameEnvBinding.EnvSnapshot memory afterInternal
        ) = rootFrameEnvBinding.snapshotAroundInternal{value: callValue}(payload);
        bytes memory expectedData = abi.encodeCall(rootFrameEnvBinding.snapshotAroundInternal, (payload));

        // ==== Assert stable frame-level bindings ====
        assertEq(beforeInternal.callFrame.self, afterInternal.callFrame.self);
        assertEq(beforeInternal.callFrame.sender, afterInternal.callFrame.sender);
        assertEq(beforeInternal.callFrame.value, afterInternal.callFrame.value);
        assertEq(beforeInternal.callFrame.sig, afterInternal.callFrame.sig);
        assertEq(beforeInternal.callFrame.dataLength, expectedData.length);
        assertEq(afterInternal.callFrame.dataLength, expectedData.length);
        assertEq(beforeInternal.callFrame.dataHash, keccak256(expectedData));
        assertEq(afterInternal.callFrame.dataHash, keccak256(expectedData));

        // ==== Assert stable transaction-level bindings ====
        assertEq(beforeInternal.transaction.txOrigin, afterInternal.transaction.txOrigin);
        assertEq(beforeInternal.transaction.txGasPrice, afterInternal.transaction.txGasPrice);

        // ==== Assert stable block-level bindings ====
        assertEq(beforeInternal.blockCtx.blockNumber, afterInternal.blockCtx.blockNumber);
        assertEq(beforeInternal.blockCtx.blockTimestamp, afterInternal.blockCtx.blockTimestamp);
        assertEq(beforeInternal.blockCtx.blockBasefee, afterInternal.blockCtx.blockBasefee);
        assertEq(beforeInternal.blockCtx.chainId, afterInternal.blockCtx.chainId);
    }
}
