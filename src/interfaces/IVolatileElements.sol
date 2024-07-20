// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IVolatileElements {
    struct UserElementData {
        uint64 lastMintTime;
    }

    struct ElementData {
        string elementName;
        mapping(address => UserElementData) userData;
    }

    function mintVolatiles(address to, uint256 elementId, uint256 amount) external;
    function burnVolatiles(address from, uint256[] calldata elementIds) external;
}
