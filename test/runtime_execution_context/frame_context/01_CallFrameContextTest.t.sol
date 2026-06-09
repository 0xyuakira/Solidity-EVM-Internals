// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../../src/runtime_execution_context/frame_context/01_call_context_switch/CallContextSwitch.sol";

/// @title CallContextSwitchTest
/// @notice Verify call context in the root call frame and under CALL-family modes
contract CallContextSwitchTest is Test {
    CallContextSwitch callContextSwitch;

    address internal constant EOA = address(0xA11CE);

    function setUp() external {
        callContextSwitch = new CallContextSwitch();
        vm.deal(EOA, 100 ether);
    }

    /// @notice Verify how call context is rebound or inherited under each call mode
    function test_call_context_transitions() external {
        bytes memory payload = hex"112233445566";
        uint256 callValue = 0.1 ether;

        vm.prank(EOA, EOA);
        (
            CallContextSwitch.CallContext memory rootCtx,
            CallContextSwitch.CallContext memory callCtx,
            CallContextSwitch.CallContext memory delegateCtx,
            CallContextSwitch.CallContext memory staticCtx
        ) = callContextSwitch.snapshotCallContextSwitch{value: callValue}(payload);

        CallContextTarget callContextTarget = callContextSwitch.target();
        bytes memory rootData = abi.encodeCall(callContextSwitch.snapshotCallContextSwitch, (payload));
        bytes memory targetData = abi.encodeCall(callContextTarget.snapshot, (payload));

        // Print reference values used to interpret the snapshots below.
        console2.log("== reference values ==");
        console2.log("EOA address:", EOA);
        console2.log("callContextSwitch address:", address(callContextSwitch));
        console2.log("CallContextTarget address:", address(callContextTarget));
        console2.log(
            "callContextSwitch.snapshotCallContextSwitch selector:",
            _toHexString(callContextSwitch.snapshotCallContextSwitch.selector)
        );
        console2.log("CallContextTarget.snapshot selector:", _toHexString(callContextTarget.snapshot.selector));
        console2.log(
            "callContextSwitch.snapshotCallContextSwitch dataHash:",
            vm.toString(keccak256(abi.encodeCall(callContextSwitch.snapshotCallContextSwitch, (payload))))
        );
        console2.log(
            "callContextTarget.snapshot dataHash:",
            vm.toString(keccak256(abi.encodeCall(callContextTarget.snapshot, (payload))))
        );
        console2.log("");

        // Print the actual call-context snapshots.
        _logContext("root call", rootCtx);
        _logContext("call", callCtx);
        _logContext("delegatecall", delegateCtx);
        _logContext("staticcall", staticCtx);

        // Verify the call-context binding rules shown in the snapshots.
        assertEq(rootCtx.self, address(callContextSwitch));
        assertEq(rootCtx.sender, EOA);
        assertEq(rootCtx.value, callValue);
        assertEq(rootCtx.sig, callContextSwitch.snapshotCallContextSwitch.selector);
        assertEq(rootCtx.dataLength, rootData.length);
        assertEq(rootCtx.dataHash, keccak256(rootData));

        assertEq(callCtx.self, address(callContextTarget));
        assertEq(callCtx.sender, address(callContextSwitch));
        assertEq(callCtx.value, callValue);
        assertEq(callCtx.sig, callContextTarget.snapshot.selector);
        assertEq(callCtx.dataLength, targetData.length);
        assertEq(callCtx.dataHash, keccak256(targetData));

        assertEq(delegateCtx.self, address(callContextSwitch));
        assertEq(delegateCtx.sender, EOA);
        assertEq(delegateCtx.value, callValue);
        assertEq(delegateCtx.sig, callContextTarget.snapshot.selector);
        assertEq(delegateCtx.dataLength, targetData.length);
        assertEq(delegateCtx.dataHash, keccak256(targetData));

        assertEq(staticCtx.self, address(callContextTarget));
        assertEq(staticCtx.sender, address(callContextSwitch));
        assertEq(staticCtx.value, 0);
        assertEq(staticCtx.sig, callContextTarget.snapshot.selector);
        assertEq(staticCtx.dataLength, targetData.length);
        assertEq(staticCtx.dataHash, keccak256(targetData));
    }

    function _logContext(string memory label, CallContextSwitch.CallContext memory ctx) internal pure {
        console2.log(string.concat("== ", label, " =="));
        console2.log("self:", ctx.self);
        console2.log("sender:", ctx.sender);
        console2.log("value:", ctx.value);
        console2.log("sig:", _toHexString(ctx.sig));
        console2.log("dataLength:", ctx.dataLength);
        console2.log("dataHash:", vm.toString(ctx.dataHash));
        console2.log("");
    }

    function _toHexString(bytes4 value) internal pure returns (string memory) {
        bytes16 hexSymbols = "0123456789abcdef";
        bytes memory buffer = new bytes(10);

        buffer[0] = "0";
        buffer[1] = "x";

        for (uint256 i; i < 4; i++) {
            uint8 b = uint8(value[i]);
            buffer[2 + i * 2] = hexSymbols[b >> 4];
            buffer[3 + i * 2] = hexSymbols[b & 0x0f];
        }

        return string(buffer);
    }
}
