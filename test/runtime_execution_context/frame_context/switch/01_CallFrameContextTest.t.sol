// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../../../src/runtime_execution_context/frame_context/switch/01_root_frame_context/RootFrameContext.sol";

/// @title CallFrameContextTest
/// @notice Verify frame-local context transition under CALL
contract CallFrameContextTest is Test {
    CallFrameContext callFrameContext;

    address internal constant EOA = address(0xA11CE);

    function setUp() external {
        callFrameContext = new CallFrameContext();
        vm.deal(EOA, 100 ether);
    }

    /// @notice Verify call-context rebinding and runtime-state reinitialization under CALL
    function test_call_frame_context() external {
        bytes memory payload = hex"112233445566";
        uint256 callValue = 1 ether;

        vm.prank(EOA, EOA);
        (CallFrameContext.FrameContextSnapshot memory beforeCall, CallFrameContext.FrameContextSnapshot memory insideChild)
        = callFrameContext.snapshotAcrossCall{value: callValue}(payload);

        bytes memory parentData = abi.encodeCall(callFrameContext.snapshotAcrossCall, (payload));
        bytes memory childData = abi.encodeCall(callFrameContext.target().snapshot, (payload));

        assertEq(beforeCall.callCtx.self, address(callFrameContext));
        assertEq(beforeCall.callCtx.sender, EOA);
        assertEq(beforeCall.callCtx.value, callValue);
        assertEq(beforeCall.callCtx.sig, callFrameContext.snapshotAcrossCall.selector);
        assertEq(beforeCall.callCtx.dataLength, parentData.length);
        assertEq(beforeCall.callCtx.dataHash, keccak256(parentData));

        assertEq(insideChild.callCtx.self, address(callFrameContext.target()));
        assertEq(insideChild.callCtx.sender, address(callFrameContext));
        assertEq(insideChild.callCtx.value, callValue);
        assertEq(insideChild.callCtx.sig, CallFrameContextTarget.snapshot.selector);
        assertEq(insideChild.callCtx.dataLength, childData.length);
        assertEq(insideChild.callCtx.dataHash, keccak256(childData));

        assertGt(beforeCall.runtime.gasLeft, insideChild.runtime.gasLeft);
        assertGe(beforeCall.runtime.memorySize, beforeCall.runtime.freeMemPtr);
        assertGe(beforeCall.runtime.freeMemPtr, 0x80);
        assertGe(insideChild.runtime.memorySize, insideChild.runtime.freeMemPtr);
        assertGe(insideChild.runtime.freeMemPtr, 0x80);
    }
}
