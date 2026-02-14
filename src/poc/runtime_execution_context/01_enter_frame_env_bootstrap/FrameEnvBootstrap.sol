// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title FrameEnvBootstrap
/// @notice Experimental contract to observe the binding state of execution-environment variables when a new call frame is entered
/// @dev The snapshot captures frame-local environment bindings at function entry:
///      - address(this), msg.sender, msg.value
///      - full calldata length/hash
///      - explicit payload view length/hash
contract FrameEnvBootstrap {
    struct EnvSnapshot {
        address self;
        address sender;
        uint256 value;
        uint256 dataLength;
        bytes32 dataHash;
        uint256 payloadLength;
        bytes32 payloadHash;
    }

    function snapshot(bytes calldata payload) external payable returns (EnvSnapshot memory env) {
        env = _capture(payload);
    }

    function snapshotPair(bytes calldata payloadA, bytes calldata payloadB)
        external
        payable
        returns (EnvSnapshot memory first, EnvSnapshot memory second)
    {
        first = _capture(payloadA);
        second = _capture(payloadB);
    }

    function _capture(bytes calldata payload) internal view returns (EnvSnapshot memory env) {
        env = EnvSnapshot({
            self: address(this),
            sender: msg.sender,
            value: msg.value,
            dataLength: msg.data.length,
            dataHash: keccak256(msg.data),
            payloadLength: payload.length,
            payloadHash: keccak256(payload)
        });
    }
}

/// @title FrameEnvBootstrapForwarder
/// @notice Minimal helper for creating a child call frame in tests
contract FrameEnvBootstrapForwarder {
    function forward(address target, bytes calldata payload)
        external
        payable
        returns (FrameEnvBootstrap.EnvSnapshot memory env)
    {
        env = FrameEnvBootstrap(target).snapshot{value: msg.value}(payload);
    }

    function forwardPair(address target, bytes calldata payloadA, bytes calldata payloadB)
        external
        payable
        returns (FrameEnvBootstrap.EnvSnapshot memory first, FrameEnvBootstrap.EnvSnapshot memory second)
    {
        (first, second) = FrameEnvBootstrap(target).snapshotPair{value: msg.value}(payloadA, payloadB);
    }
}
