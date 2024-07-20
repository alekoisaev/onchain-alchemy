// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC1155Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract VolatileElements is ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // === STORAGE ===
    struct UserElementData {
        uint64 lastMintTime;
    }

    struct ElementData {
        string elementName;
        mapping(address => UserElementData) userData;
    }

    address public mergeContract;
    address public morphContract;

    mapping(uint256 => ElementData) public elementURIs;

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    // === Main ===

    function mintVolatiles(address to, uint256 elementId, uint256 amount) external {
        if (msg.sender != morphContract) revert OwnableUnauthorizedAccount(msg.sender);

        elementURIs[elementId].userData[to].lastMintTime = uint64(block.timestamp);
        _mint(to, elementId, amount, "");
    }

    function burnVolatiles(address from, uint256[] calldata elementIds) external {
        if (msg.sender != mergeContract) revert OwnableUnauthorizedAccount(msg.sender);

        for (uint256 i; i < elementIds.length;) {
            _burn(from, elementIds[i], 1);

            unchecked {
                ++i;
            }
        }
    }

    // === view ===
    function getAliveVolatilesCount(address user, uint256 elementId) public view returns (uint256 alivesCount) {
        uint256 _lastMintTime = elementURIs[elementId].userData[user].lastMintTime;
        uint256 daysAfterMint = (block.timestamp - _lastMintTime) / 24;

        alivesCount = balanceOf(user, elementId) - daysAfterMint;
    }

    function uri(uint256 id) public view override returns (string memory) {}

    // == admin ==
    function setExtenalContracts(address _mergeContract, address _morphContract) external onlyOwner {
        mergeContract = _mergeContract;
        morphContract = _morphContract;
    }

    // === overrides ===

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
