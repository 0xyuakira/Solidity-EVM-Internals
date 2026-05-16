// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../../../src/runtime_execution_context/frame_context/switch/01_root_frame_context/RootFrameContext.sol";

/// @title RootFrameContextTest
/// @notice Verify root-frame-local context initialization
contract RootFrameContextTest is Test {
    RootFrameContext rootFrameContext;

    address internal constant EOA = address(0xA11CE);

    function setUp() external {
        rootFrameContext = new RootFrameContext();
        vm.deal(EOA, 100 ether);
    }

    /// @notice Verify root-frame call context and runtime context initialization
    function test_root_frame_context() external {
        bytes memory payload = hex"112233445566";
        uint256 callValue = 1 ether;

        vm.prank(EOA, EOA);
        RootFrameContext.FrameContextSnapshot memory snap = rootFrameContext.snapshot{value: callValue}(payload);

        bytes memory expectedData = abi.encodeCall(rootFrameContext.snapshot, (payload));

        assertEq(snap.callCtx.self, address(rootFrameContext));
        assertEq(snap.callCtx.sender, EOA);
        assertEq(snap.callCtx.value, callValue);
        assertEq(snap.callCtx.sig, rootFrameContext.snapshot.selector);
        assertEq(snap.callCtx.dataLength, expectedData.length);
        assertEq(snap.callCtx.dataHash, keccak256(expectedData));

        assertGt(snap.runtime.gasLeft, 0);
        // free memory pointer lives at 0x40 and should point into allocated memory.
        assertGe(snap.runtime.memorySize, snap.runtime.freeMemPtr);
        assertGe(snap.runtime.freeMemPtr, 0x80);
    }
}
