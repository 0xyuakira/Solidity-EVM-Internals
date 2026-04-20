// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title RootFrameEnvBinding
/// @notice Experimental contract to observe the binding state of execution-environment variables when the root call frame is entered
/// @dev The snapshot captures root-call-frame environment bindings at function entry:
///      - call-frame level variables
///      - transaction-level variables
///      - block-level variables
contract RootFrameEnvBinding {
    struct CallFrameEnv {
        address self;
        address sender;
        uint256 value;
        bytes4 sig;
        uint256 dataLength;
        bytes32 dataHash;
    }

    struct TransactionEnv {
        address txOrigin;
        uint256 txGasPrice;
    }

    struct BlockEnv {
        uint256 blockNumber;
        uint256 blockTimestamp;
        uint256 blockBasefee;
        uint256 chainId;
    }

    struct EnvSnapshot {
        CallFrameEnv callFrame;
        TransactionEnv transaction;
        BlockEnv blockCtx;
    }

    /// @dev Capture one environment snapshot at root-frame function entry.
    function snapshot(bytes calldata payload) external payable returns (EnvSnapshot memory env) {
        payload;
        env = _capture();
    }

    /// @dev Capture two snapshots in one frame: before and inside an internal call.
    function snapshotAroundInternal(bytes calldata payload)
        external
        payable
        returns (EnvSnapshot memory beforeInternal, EnvSnapshot memory afterInternal)
    {
        beforeInternal = _capture();
        afterInternal = _internalProbe(payload);
    }

    function _capture() internal view returns (EnvSnapshot memory env) {
        env.callFrame = CallFrameEnv({
            self: address(this),
            sender: msg.sender,
            value: msg.value,
            sig: msg.sig,
            dataLength: msg.data.length,
            dataHash: keccak256(msg.data)
        });

        env.transaction = TransactionEnv({txOrigin: tx.origin, txGasPrice: tx.gasprice});

        env.blockCtx = BlockEnv({
            blockNumber: block.number,
            blockTimestamp: block.timestamp,
            blockBasefee: block.basefee,
            chainId: block.chainid
        });
    }

    function _internalProbe(bytes calldata payload) internal view returns (EnvSnapshot memory env) {
        payload;
        env = _capture();
    }
}
