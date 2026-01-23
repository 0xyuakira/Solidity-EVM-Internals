// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title SlotWidth
/// @notice Experiment contract for storage slot width invariance
contract SlotWidth {
    bytes public data;

    /// @notice Set dynamic bytes
    function set(bytes calldata b) external {
        data = b;
    }

    /// @notice Helper to get keccak(slot) for dynamic data start
    function dataSlot() external pure returns (bytes32) {
        return keccak256(abi.encode(uint256(0)));
    }
}
