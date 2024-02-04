//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract MappingToArrays {
    // Mapping from uint256 to array of addresses
    mapping(uint256 => uint256[]) private uint256ToArrayMapping;

    // Function to add an address to the array associated with a uint256 key
    function addToMapping(uint256 key, uint256 value) public {
        uint256ToArrayMapping[key].push(value);
    }

    // Function to get the array associated with a uint256 key
    function getArray(uint256 key) external view returns (uint256[] memory) {
        return uint256ToArrayMapping[key];
    }

    // Function to get the length of the array associated with a uint256 key
    function getArrayLength(uint256 key) external view returns (uint256) {
        return uint256ToArrayMapping[key].length;
    }
}
