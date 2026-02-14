// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/runtime_execution_context/01_enter_frame_env_bootstrap/FrameEnvBootstrap.sol";

/// @title FrameEnvBootstrapTest
/// @notice Verify environment binding semantics at call-frame entry
contract FrameEnvBootstrapTest is Test {
    FrameEnvBootstrap frameEnvBootstrap;
    FrameEnvBootstrapForwarder frameEnvBootstrapForwarder;
    address internal constant EOA = address(0xA11CE);

    /// @notice Deploy PoC contracts before each test
    function setUp() public {
        frameEnvBootstrap = new FrameEnvBootstrap();
        frameEnvBootstrapForwarder = new FrameEnvBootstrapForwarder();
        vm.deal(EOA, 100 ether);
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

        // ==== Assert calldata/input-view bindings ====
        assertEq(env.dataLength, expectedData.length);
        assertEq(env.dataHash, keccak256(expectedData));
        assertEq(env.payloadLength, payload.length);
        assertEq(env.payloadHash, keccak256(payload));
    }

    /// @notice Child-frame observation: call is forwarded to create a new frame
    function test_child_frame_env_bootstrap() public {
        // ==== Input ====
        bytes memory payload = hex"abcdef001122334455";
        uint256 callValue = 0.25 ether;

        // ==== Execute ====
        vm.prank(EOA, EOA);
        FrameEnvBootstrap.EnvSnapshot memory env =
            frameEnvBootstrapForwarder.forward{value: callValue}(address(frameEnvBootstrap), payload);
        bytes memory expectedData = abi.encodeCall(frameEnvBootstrap.snapshot, (payload));

        // ==== Assert frame-level bindings ====
        assertEq(env.self, address(frameEnvBootstrap));
        assertEq(env.sender, address(frameEnvBootstrapForwarder));
        assertEq(env.value, callValue);

        // ==== Assert calldata/input-view bindings ====
        assertEq(env.dataLength, expectedData.length);
        assertEq(env.dataHash, keccak256(expectedData));
        assertEq(env.payloadLength, payload.length);
        assertEq(env.payloadHash, keccak256(payload));
    }

    /// @notice Same-frame stability in root call: frame-level bindings remain unchanged
    function test_same_frame_binding_stability_root() public {
        // ==== Input ====
        bytes memory payloadA = hex"aa";
        bytes memory payloadB = hex"bbbbcc";
        uint256 callValue = 0.5 ether;

        // ==== Execute two captures within one frame ====
        vm.prank(EOA, EOA);
        (FrameEnvBootstrap.EnvSnapshot memory first, FrameEnvBootstrap.EnvSnapshot memory second) =
            frameEnvBootstrap.snapshotPair{value: callValue}(payloadA, payloadB);

        // ==== Assert stable frame-level bindings ====
        assertEq(first.sender, EOA);
        assertEq(second.sender, EOA);
        assertEq(first.self, second.self);
        assertEq(first.sender, second.sender);
        assertEq(first.value, second.value);
        assertEq(first.dataLength, second.dataLength);
        assertEq(first.dataHash, second.dataHash);

        // ==== Assert payload-specific differences ====
        assertEq(first.payloadLength, payloadA.length);
        assertEq(second.payloadLength, payloadB.length);
        assertEq(first.payloadHash, keccak256(payloadA));
        assertEq(second.payloadHash, keccak256(payloadB));
    }

    /// @notice Same-frame stability in child call: forwarded frame-level bindings remain unchanged
    function test_same_frame_binding_stability_child() public {
        // ==== Input ====
        bytes memory payloadA = hex"1122";
        bytes memory payloadB = hex"aabbccddeeff";
        uint256 callValue = 0.125 ether;

        // ==== Execute two captures within one forwarded frame ====
        vm.prank(EOA, EOA);
        (FrameEnvBootstrap.EnvSnapshot memory first, FrameEnvBootstrap.EnvSnapshot memory second) =
            frameEnvBootstrapForwarder.forwardPair{value: callValue}(address(frameEnvBootstrap), payloadA, payloadB);
        bytes memory expectedData = abi.encodeCall(frameEnvBootstrap.snapshotPair, (payloadA, payloadB));

        // ==== Assert stable frame-level bindings ====
        assertEq(first.self, address(frameEnvBootstrap));
        assertEq(second.self, address(frameEnvBootstrap));
        assertEq(first.sender, address(frameEnvBootstrapForwarder));
        assertEq(second.sender, address(frameEnvBootstrapForwarder));
        assertEq(first.value, callValue);
        assertEq(second.value, callValue);
        assertEq(first.dataLength, expectedData.length);
        assertEq(second.dataLength, expectedData.length);
        assertEq(first.dataHash, keccak256(expectedData));
        assertEq(second.dataHash, keccak256(expectedData));

        // ==== Assert payload-specific differences ====
        assertEq(first.payloadHash, keccak256(payloadA));
        assertEq(second.payloadHash, keccak256(payloadB));
    }
}
