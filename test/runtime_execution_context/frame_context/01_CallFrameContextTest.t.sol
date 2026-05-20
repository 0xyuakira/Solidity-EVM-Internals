// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../../src/runtime_execution_context/frame_context/01_call_context_switch/CallContextSwitch.sol";

/// @title CallContextSwitchTest
/// @notice Verify call-context transition across root entry, CALL, DELEGATECALL, and STATICCALL
contract CallContextSwitchTest is Test {
    CallContextSwitch callContextSwitch;

    address internal constant EOA = address(0xA11CE);

    function setUp() external {
        callContextSwitch = new CallContextSwitch();
        vm.deal(EOA, 100 ether);
    }

    /// @notice Verify rebinding and inheritance rules for frame-local call context
    function test_call_context_transitions() external {
        bytes memory payload = hex"112233445566";
        uint256 callValue = 1 ether;

        vm.prank(EOA, EOA);
        (
            CallContextSwitch.CallContext memory rootCtx,
            CallContextSwitch.CallContext memory callCtx,
            CallContextSwitch.CallContext memory delegateCtx,
            CallContextSwitch.CallContext memory staticCtx
        ) = callContextSwitch.snapshotAcrossTransitions{value: callValue}(payload);

        CallContextTarget target = callContextSwitch.target();
        bytes memory rootData = abi.encodeCall(callContextSwitch.snapshotAcrossTransitions, (payload));
        bytes memory childData = abi.encodeWithSelector(CallContextTarget.snapshot.selector, payload);

        _logContext("root", rootCtx);
        _logContext("call", callCtx);
        _logContext("delegatecall", delegateCtx);
        _logContext("staticcall", staticCtx);

        assertEq(rootCtx.self, address(callContextSwitch));
        assertEq(rootCtx.sender, EOA);
        assertEq(rootCtx.value, callValue);
        assertEq(rootCtx.sig, callContextSwitch.snapshotAcrossTransitions.selector);
        assertEq(rootCtx.dataLength, rootData.length);
        assertEq(rootCtx.dataHash, keccak256(rootData));

        assertEq(callCtx.self, address(target));
        assertEq(callCtx.sender, address(callContextSwitch));
        assertEq(callCtx.value, callValue);
        assertEq(callCtx.sig, CallContextTarget.snapshot.selector);
        assertEq(callCtx.dataLength, childData.length);
        assertEq(callCtx.dataHash, keccak256(childData));

        assertEq(delegateCtx.self, address(callContextSwitch));
        assertEq(delegateCtx.sender, EOA);
        assertEq(delegateCtx.value, callValue);
        assertEq(delegateCtx.sig, CallContextTarget.snapshot.selector);
        assertEq(delegateCtx.dataLength, childData.length);
        assertEq(delegateCtx.dataHash, keccak256(childData));

        assertEq(staticCtx.self, address(target));
        assertEq(staticCtx.sender, address(callContextSwitch));
        assertEq(staticCtx.value, 0);
        assertEq(staticCtx.sig, CallContextTarget.snapshot.selector);
        assertEq(staticCtx.dataLength, childData.length);
        assertEq(staticCtx.dataHash, keccak256(childData));
    }

    function _logContext(string memory label, CallContextSwitch.CallContext memory ctx) internal pure {
        console2.log(string.concat("== ", label, " =="));
        console2.log("self", ctx.self);
        console2.log("sender", ctx.sender);
        console2.log("value", ctx.value);
        console2.logBytes4(ctx.sig);
        console2.log("dataLength", ctx.dataLength);
        console2.logBytes32(ctx.dataHash);
        console2.log("");
    }
}
