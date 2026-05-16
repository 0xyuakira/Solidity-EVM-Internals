// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title RootFrameContext
/// @notice Observe the initialized frame-local context when a root call frame is entered.
/// @dev The snapshot captures root-frame-local context at frame establishment:
///      - call context: address(this), msg.sender, msg.value, msg.sig, msg.data
///      - runtime context: gasleft(), msize(), mload(0x40)
contract RootFrameContext {
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

    /// @notice Capture the observable frame-local context in the root call frame.
    function snapshot(bytes calldata) external payable returns (FrameContextSnapshot memory snap) {
        snap = _capture();
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
