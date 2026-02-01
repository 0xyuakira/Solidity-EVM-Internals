// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title MappingSlotDerivation
/// @notice Experimental contract to demonstrate how `mapping` are stored in EVM storage
/// @dev Proof-of-concept (PoC) contract declaring multiple mapping state variables:
///      - Simple value-type mapping (uint256 → uint256)
///      - Address-keyed mapping (address → uint128)
///      - Mapping to dynamic array (bytes32 → bytes[]):
///      Mappings are left empty; elements will be set during tests.
contract MappingSlotDerivation {
    mapping(uint256 => uint256) public basicMap;

    mapping(address => uint128) public addrMap;

    mapping(bytes32 => bytes[]) public nestedMap;

    function setBasicMap(uint256 key, uint256 value) external {
        basicMap[key] = value;
    }

    function setAddrMap(address key, uint128 value) external {
        addrMap[key] = value;
    }

    function setNestedMap(bytes32 key, bytes calldata value) external {
        nestedMap[key].push(value);
    }
}
