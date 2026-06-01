// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

abstract contract CallContextCapture {
    struct CallContext {
        address self;
        address sender;
        uint256 value;
        bytes4 sig;
        uint256 dataLength;
        bytes32 dataHash;
    }

    function _capture() internal view returns (CallContext memory ctx) {
        ctx = CallContext({
            self: address(this),
            sender: msg.sender,
            value: msg.value,
            sig: msg.sig,
            dataLength: msg.data.length,
            dataHash: keccak256(msg.data)
        });
    }
}

/// @title CallContextTarget
/// @notice Capture call context in the called frame under different external call modes.
contract CallContextTarget is CallContextCapture {
    function snapshot(bytes calldata payload) external payable returns (CallContext memory ctx) {
        payload;
        ctx = _capture();
    }
}

/// @title CallContextSwitch
/// @notice Compare call context in the root call frame and under CALL-family modes.
/// @dev The observation surface is limited to call context:
///      - address(this), msg.sender, msg.value, msg.sig, msg.data
contract CallContextSwitch is CallContextCapture {
    CallContextTarget public immutable target;

    constructor() {
        target = new CallContextTarget();
    }

    /// @notice Capture root-frame call context, then capture call contexts under CALL, DELEGATECALL, and STATICCALL.
    function snapshotCallContextSwitch(bytes calldata payload)
        external
        payable
        returns (
            CallContext memory rootCtx,
            CallContext memory callCtx,
            CallContext memory delegateCtx,
            CallContext memory staticCtx
        )
    {
        rootCtx = _capture();
        callCtx = target.snapshot{value: msg.value}(payload);
        delegateCtx = _snapshotViaDelegatecall(payload);
        staticCtx = _snapshotViaStaticcall(payload);
    }

    function _snapshotViaDelegatecall(bytes calldata payload) internal returns (CallContext memory ctx) {
        (bool ok, bytes memory ret) =
            address(target).delegatecall(abi.encodeWithSelector(CallContextTarget.snapshot.selector, payload));
        require(ok, "delegatecall snapshot failed");
        ctx = abi.decode(ret, (CallContext));
    }

    function _snapshotViaStaticcall(bytes calldata payload) internal view returns (CallContext memory ctx) {
        (bool ok, bytes memory ret) =
            address(target).staticcall(abi.encodeWithSelector(CallContextTarget.snapshot.selector, payload));
        require(ok, "staticcall snapshot failed");
        ctx = abi.decode(ret, (CallContext));
    }
}
