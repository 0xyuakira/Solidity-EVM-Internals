// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title SlotWidth
/// @notice Experimental contract to demonstrate that a single storage slot in EVM is limited to 256 bits
/// @dev Proof-of-concept (PoC) contract with minimal state:
///      - one dynamic bytes variable
///      - helper to get the starting storage slot for raw inspection
///      Used for testing storage slot width invariance.
contract SlotWidth {
    /// @notice Dynamic bytes used to probe slot boundaries
    /// @dev For dynamic bytes, the actual data starts at keccak256(slot)
    bytes public data;

    /// @notice Store arbitrary-length bytes
    /// @param b The byte sequence to store
    /// @dev Only triggers Solidity's dynamic bytes storage encoding
    function set(bytes calldata b) external {
        data = b;
    }

    /// @notice Returns the starting storage slot of the dynamic data
    /// @return slot The first storage slot containing the byte data
    function dataSlot() external pure returns (uint256) {
        return uint256(keccak256(abi.encode(uint256(0))));
    }
}
