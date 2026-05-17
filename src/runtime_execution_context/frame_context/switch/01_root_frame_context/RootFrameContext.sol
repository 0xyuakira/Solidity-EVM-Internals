// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

abstract contract FrameContextCapture {
    struct CallContext {
        address self;
        address sender;
        uint256 value;
        bytes4 sig;
        uint256 dataLength;
        bytes32 dataHash;
    }

    struct RuntimeContext {
        uint256 gasLeft;
        uint256 memorySize;
        uint256 freeMemPtr;
    }

    struct FrameContextSnapshot {
        CallContext callCtx;
        RuntimeContext runtime;
    }

    function _capture() internal view returns (FrameContextSnapshot memory snap) {
        uint256 memSize;
        uint256 freePtr;

        assembly {
            memSize := msize()
            freePtr := mload(0x40)
        }

        snap.callCtx = CallContext({
            self: address(this),
            sender: msg.sender,
            value: msg.value,
            sig: msg.sig,
            dataLength: msg.data.length,
            dataHash: keccak256(msg.data)
        });

        snap.runtime = RuntimeContext({gasLeft: gasleft(), memorySize: memSize, freeMemPtr: freePtr});
    }
}

/// @title CallFrameContextTarget
/// @notice Capture child-frame-local context at call-frame entry.
contract CallFrameContextTarget is FrameContextCapture {
    function snapshot(bytes calldata) external payable returns (FrameContextSnapshot memory snap) {
        snap = _capture();
    }
}

/// @title CallFrameContext
/// @notice Observe frame-local context before and at child-frame entry under CALL.
/// @dev The snapshots cover the same frame-local observation surface across a CALL transition:
///      - call context: address(this), msg.sender, msg.value, msg.sig, msg.data
///      - runtime context: gasleft(), msize(), mload(0x40)
contract CallFrameContext is FrameContextCapture {
    CallFrameContextTarget public immutable target;

    constructor() {
        target = new CallFrameContextTarget();
    }

    /// @notice Capture one parent-frame snapshot, then one child-frame-entry snapshot under CALL.
    function snapshotAcrossCall(bytes calldata payload)
        external
        payable
        returns (FrameContextSnapshot memory beforeCall, FrameContextSnapshot memory insideChild)
    {
        beforeCall = _capture();
        insideChild = target.snapshot{value: msg.value}(payload);
    }
}
