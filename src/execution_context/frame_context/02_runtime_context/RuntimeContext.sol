// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

struct RuntimeSnapshot {
    uint256 gasLeft;
    uint256 memorySize;
    uint256 freeMemoryPointer;
    bytes32 memoryMarker;
}

struct ChildRuntimeSnapshots {
    RuntimeSnapshot atEntry;
    RuntimeSnapshot beforeReturn;
}

struct GasSnapshot {
    uint256 gasLeft;
}

/// @title RuntimeContextTarget
/// @notice Provide child-frame execution paths for runtime-context observation.
contract RuntimeContextTarget {
    /// @notice Capture gas and memory state before and after writing a marker in the child frame.
    function snapshot(bytes32 childMarker) external payable returns (ChildRuntimeSnapshots memory) {
        assembly {
            let entryGas := gas()
            let entryMemorySize := msize()
            let entryFreeMemoryPointer := mload(0x40)
            let entryMemoryMarker := mload(0x2000)

            mstore(0x2000, childMarker)

            let returnGas := gas()
            let returnMemorySize := msize()
            let returnFreeMemoryPointer := mload(0x40)
            let returnMemoryMarker := mload(0x2000)

            let result := mload(0x40)
            mstore(result, entryGas)
            mstore(add(result, 0x20), entryMemorySize)
            mstore(add(result, 0x40), entryFreeMemoryPointer)
            mstore(add(result, 0x60), entryMemoryMarker)
            mstore(add(result, 0x80), returnGas)
            mstore(add(result, 0xa0), returnMemorySize)
            mstore(add(result, 0xc0), returnFreeMemoryPointer)
            mstore(add(result, 0xe0), returnMemoryMarker)

            return(result, 0x100)
        }
    }

    /// @notice Return a fixed-width payload for return-data observation.
    function returnPayload(bytes32 payload) external payable {
        assembly {
            mstore(0x00, payload)
            return(0x00, 0x20)
        }
    }

    /// @notice Revert with a fixed-width payload for revert-data observation.
    function revertPayload(bytes32 payload) external payable {
        assembly {
            mstore(0x00, payload)
            revert(0x00, 0x20)
        }
    }

    /// @notice Execute a compact arithmetic path intended for opcode-level stack tracing.
    function stackProbe(uint256 left, uint256 right) external payable returns (uint256 result) {
        assembly {
            result := mul(add(left, right), 2)
        }
    }
}

/// @title RuntimeContext
/// @notice Compare frame runtime state under CALL, DELEGATECALL, and STATICCALL.
/// @dev The observation surface is limited to:
///      - EVM operand stack
///      - memory, msize(), and the free memory pointer
///      - gas available to the parent and child frames
///      - return data produced by successful and reverted calls
contract RuntimeContext {
    enum CallMode {
        Call,
        DelegateCall,
        StaticCall
    }

    struct CallResult {
        bool success;
        GasSnapshot beforeCall;
        GasSnapshot afterCall;
        uint256 returnDataSize;
        bytes32 returnDataHash;
    }

    struct RuntimeTransition {
        RuntimeSnapshot rootBeforeCall;
        RuntimeSnapshot childAtEntry;
        RuntimeSnapshot childBeforeReturn;
        RuntimeSnapshot rootAfterCall;
        CallResult callResult;
    }

    bytes32 public constant ROOT_MARKER = keccak256("ROOT_FRAME_MEMORY");

    RuntimeContextTarget public immutable target;

    constructor() {
        target = new RuntimeContextTarget();
    }

    /// @notice Capture parent and child runtime state around one selected call mode.
    function snapshotRuntimeContext(CallMode mode, bytes32 childMarker)
        external
        payable
        returns (RuntimeTransition memory transition)
    {
        bytes memory input = abi.encodeCall(RuntimeContextTarget.snapshot, (childMarker));
        bytes32 rootMarker = ROOT_MARKER;

        assembly {
            mstore(0x2000, rootMarker)
        }

        transition.rootBeforeCall = _captureRuntimeSnapshot();

        bytes memory returnData;
        (transition.callResult, returnData) = _invoke(mode, input, msg.value);
        require(transition.callResult.success, "runtime snapshot failed");

        ChildRuntimeSnapshots memory child = abi.decode(returnData, (ChildRuntimeSnapshots));
        transition.childAtEntry = child.atEntry;
        transition.childBeforeReturn = child.beforeReturn;
        transition.rootAfterCall = _captureRuntimeSnapshot();
    }

    /// @notice Capture successive return-data buffers after success, revert, and replacement calls.
    function snapshotReturnDataSequence(
        CallMode mode,
        bytes32 firstPayload,
        bytes32 revertPayload,
        bytes32 replacementPayload
    )
        external
        returns (
            CallResult memory firstResult,
            CallResult memory revertResult,
            CallResult memory replacementResult
        )
    {
        bytes memory firstInput = abi.encodeCall(RuntimeContextTarget.returnPayload, (firstPayload));
        bytes memory revertInput = abi.encodeCall(RuntimeContextTarget.revertPayload, (revertPayload));
        bytes memory replacementInput = abi.encodeCall(RuntimeContextTarget.returnPayload, (replacementPayload));

        (firstResult,) = _invoke(mode, firstInput, 0);
        (revertResult,) = _invoke(mode, revertInput, 0);
        (replacementResult,) = _invoke(mode, replacementInput, 0);
    }

    /// @notice Run a small arithmetic path under one selected call mode for stack tracing.
    function runStackProbe(CallMode mode, uint256 left, uint256 right)
        external
        payable
        returns (CallResult memory callResult, uint256 result)
    {
        bytes memory input = abi.encodeCall(RuntimeContextTarget.stackProbe, (left, right));
        bytes memory returnData;

        (callResult, returnData) = _invoke(mode, input, msg.value);
        require(callResult.success, "stack probe failed");

        result = abi.decode(returnData, (uint256));
    }

    function _captureRuntimeSnapshot() internal view returns (RuntimeSnapshot memory snapshot) {
        assembly {
            mstore(snapshot, gas())
            mstore(add(snapshot, 0x20), msize())
            mstore(add(snapshot, 0x40), mload(0x40))
            mstore(add(snapshot, 0x60), mload(0x2000))
        }
    }

    function _invoke(CallMode mode, bytes memory input, uint256 callValue)
        internal
        returns (CallResult memory result, bytes memory returnData)
    {
        address targetAddress = address(target);
        bool success;
        uint256 gasBeforeCall;
        uint256 gasAfterCall;
        uint256 returnDataSize;

        if (mode == CallMode.Call) {
            assembly {
                gasBeforeCall := gas()
                success := call(gas(), targetAddress, callValue, add(input, 0x20), mload(input), 0, 0)
                gasAfterCall := gas()
                returnDataSize := returndatasize()
            }
        } else if (mode == CallMode.DelegateCall) {
            assembly {
                gasBeforeCall := gas()
                success := delegatecall(gas(), targetAddress, add(input, 0x20), mload(input), 0, 0)
                gasAfterCall := gas()
                returnDataSize := returndatasize()
            }
        } else {
            assembly {
                gasBeforeCall := gas()
                success := staticcall(gas(), targetAddress, add(input, 0x20), mload(input), 0, 0)
                gasAfterCall := gas()
                returnDataSize := returndatasize()
            }
        }

        returnData = new bytes(returnDataSize);
        assembly {
            returndatacopy(add(returnData, 0x20), 0, returnDataSize)
        }

        result = CallResult({
            success: success,
            beforeCall: GasSnapshot({gasLeft: gasBeforeCall}),
            afterCall: GasSnapshot({gasLeft: gasAfterCall}),
            returnDataSize: returnDataSize,
            returnDataHash: keccak256(returnData)
        });
    }
}
