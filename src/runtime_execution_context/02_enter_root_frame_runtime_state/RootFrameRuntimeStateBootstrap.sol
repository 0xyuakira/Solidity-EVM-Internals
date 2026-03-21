// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title RootFrameRuntimeStateBootstrap
/// @notice Experimental contract to observe runtime-state values when the root call frame is entered
/// @dev Captures execution-state and memory-state values at observation points in the same root call frame.
contract RootFrameRuntimeStateBootstrap {
    struct ExecutionState {
        uint256 gasLeft;
        uint256 returnDataSize;
    }

    struct MemoryState {
        uint256 memorySize;
        uint256 freeMemPtr;
    }

    struct RuntimeSnapshot {
        ExecutionState execution;
        MemoryState memoryState;
    }

    /// @notice Capture one runtime-state snapshot at root-frame function entry.
    function snapshot(bytes calldata payload) external payable returns (RuntimeSnapshot memory snap) {
        payload;
        snap = _capture();
    }

    /// @notice Capture two snapshots in one frame: before and inside an internal call.
    function snapshotAroundInternal(bytes calldata payload)
        external
        payable
        returns (RuntimeSnapshot memory beforeInternal, RuntimeSnapshot memory insideInternal)
    {
        beforeInternal = _capture();
        insideInternal = _internalProbe(payload);
    }

    /// @dev Build one runtime-state snapshot from execution and memory observables.
    function _capture() internal view returns (RuntimeSnapshot memory snap) {
        uint256 retSize;
        uint256 memSize;
        uint256 freePtr;

        assembly {
            retSize := returndatasize()
            memSize := msize()
            freePtr := mload(0x40)
        }

        snap.execution = ExecutionState({gasLeft: gasleft(), returnDataSize: retSize});
        snap.memoryState = MemoryState({memorySize: memSize, freeMemPtr: freePtr});
    }

    /// @dev Internal observation point with memory/gas activity before the second capture.
    function _internalProbe(bytes calldata payload) internal view returns (RuntimeSnapshot memory snap) {
        uint256 witness = payload.length + 1;
        witness;
        snap = _capture();
    }
}
