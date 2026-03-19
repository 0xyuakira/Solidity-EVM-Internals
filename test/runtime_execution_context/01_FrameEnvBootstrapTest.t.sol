// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/runtime_execution_context/01_enter_frame_env_bootstrap/FrameEnvBootstrap.sol";

/// @title FrameEnvBootstrapTest
/// @notice Verify environment binding semantics at call-frame entry
contract FrameEnvBootstrapTest is Test {
    FrameEnvBootstrap frameEnvBootstrap;
    address internal constant EOA = address(0xA11CE);
    uint256 internal constant TEST_GAS_PRICE = 7 gwei;
    uint256 internal constant TEST_BASEFEE = 1 gwei;
    uint256 internal constant TEST_BLOCK_NUMBER = 1_234_567;
    uint256 internal constant TEST_BLOCK_TIMESTAMP = 1_700_000_000;

    /// @notice Deploy PoC contracts before each test
    function setUp() public {
        frameEnvBootstrap = new FrameEnvBootstrap();
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
        FrameEnvBootstrap.EnvSnapshot memory env = frameEnvBootstrap.snapshot{value: callValue}(payload);
        bytes memory expectedData = abi.encodeCall(frameEnvBootstrap.snapshot, (payload));

        // ==== Assert frame-level bindings ====
        assertEq(env.self, address(frameEnvBootstrap));
        assertEq(env.sender, EOA);
        assertEq(env.value, callValue);
        assertEq(env.sig, frameEnvBootstrap.snapshot.selector);

        // ==== Assert transaction-level bindings ====
        assertEq(env.txOrigin, EOA);
        assertEq(env.txGasPrice, TEST_GAS_PRICE);

        // ==== Assert block-level bindings ====
        assertEq(env.blockNumber, TEST_BLOCK_NUMBER);
        assertEq(env.blockTimestamp, TEST_BLOCK_TIMESTAMP);
        assertEq(env.blockBasefee, TEST_BASEFEE);
        assertEq(env.chainId, block.chainid);

        // ==== Assert calldata/input-view bindings ====
        assertEq(env.dataLength, expectedData.length);
        assertEq(env.dataHash, keccak256(expectedData));
        assertEq(env.payloadLength, payload.length);
        assertEq(env.payloadHash, keccak256(payload));
    }

    /// @notice Same-frame stability: internal call does not change environment bindings
    function test_same_frame_binding_stability_with_internal_call() public {
        // ==== Input ====
        bytes memory payload = hex"1122aabbccdd";
        uint256 callValue = 0.5 ether;

        // ==== Execute with one internal call between two captures ====
        vm.prank(EOA, EOA);
        (
            FrameEnvBootstrap.EnvSnapshot memory beforeInternal,
            FrameEnvBootstrap.EnvSnapshot memory afterInternal
        ) = frameEnvBootstrap.snapshotAroundInternal{value: callValue}(payload);
        bytes memory expectedData = abi.encodeCall(frameEnvBootstrap.snapshotAroundInternal, (payload));

        // ==== Assert stable frame-level bindings ====
        assertEq(beforeInternal.self, afterInternal.self);
        assertEq(beforeInternal.sender, afterInternal.sender);
        assertEq(beforeInternal.value, afterInternal.value);
        assertEq(beforeInternal.sig, afterInternal.sig);

        // ==== Assert stable transaction-level bindings ====
        assertEq(beforeInternal.txOrigin, afterInternal.txOrigin);
        assertEq(beforeInternal.txGasPrice, afterInternal.txGasPrice);

        // ==== Assert stable block-level bindings ====
        assertEq(beforeInternal.blockNumber, afterInternal.blockNumber);
        assertEq(beforeInternal.blockTimestamp, afterInternal.blockTimestamp);
        assertEq(beforeInternal.blockBasefee, afterInternal.blockBasefee);
        assertEq(beforeInternal.chainId, afterInternal.chainId);

        // ==== Assert stable calldata/input-view bindings ====
        assertEq(beforeInternal.dataLength, expectedData.length);
        assertEq(afterInternal.dataLength, expectedData.length);
        assertEq(beforeInternal.dataHash, keccak256(expectedData));
        assertEq(afterInternal.dataHash, keccak256(expectedData));
        assertEq(beforeInternal.payloadLength, payload.length);
        assertEq(afterInternal.payloadLength, payload.length);
        assertEq(beforeInternal.payloadHash, keccak256(payload));
        assertEq(afterInternal.payloadHash, keccak256(payload));
    }
}
