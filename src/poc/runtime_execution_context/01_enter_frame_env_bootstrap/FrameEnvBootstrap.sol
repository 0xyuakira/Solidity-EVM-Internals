// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title FrameEnvBootstrap
/// @notice Experimental contract to observe the binding state of execution-environment variables when a new call frame is entered
/// @dev The snapshot captures frame-local environment bindings at function entry:
///      - call-frame level variables
///      - transaction-level variables
///      - block-level variables
contract FrameEnvBootstrap {
    struct EnvSnapshot {
        address self;
        address sender;
        uint256 value;
        bytes4 sig;
        uint256 dataLength;
        bytes32 dataHash;
        address txOrigin;
        uint256 txGasPrice;
        uint256 blockNumber;
        uint256 blockTimestamp;
        uint256 blockBasefee;
        uint256 chainId;
        uint256 payloadLength;
        bytes32 payloadHash;
    }

    function snapshot(bytes calldata payload) external payable returns (EnvSnapshot memory env) {
        env = _capture(payload);
    }

    function snapshotAroundInternal(bytes calldata payload)
        external
        payable
        returns (EnvSnapshot memory beforeInternal, EnvSnapshot memory afterInternal)
    {
        beforeInternal = _capture(payload);
        _internalProbe(payload);
        afterInternal = _capture(payload);
    }

    function _capture(bytes calldata payload) internal view returns (EnvSnapshot memory env) {
        env = EnvSnapshot({
            self: address(this),
            sender: msg.sender,
            value: msg.value,
            sig: msg.sig,
            dataLength: msg.data.length,
            dataHash: keccak256(msg.data),
            txOrigin: tx.origin,
            txGasPrice: tx.gasprice,
            blockNumber: block.number,
            blockTimestamp: block.timestamp,
            blockBasefee: block.basefee,
            chainId: block.chainid,
            payloadLength: payload.length,
            payloadHash: keccak256(payload)
        });
    }

    function _internalProbe(bytes calldata payload) internal pure returns (uint256 witness) {
        witness = payload.length + 1;
    }
}
