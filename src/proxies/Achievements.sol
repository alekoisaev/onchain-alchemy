// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC1155Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import {IAlchemistProfile} from "../interfaces/IAlchemistProfile.sol";
import {IElements} from "../interfaces/IElements.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

contract Achievements is ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    error NotProfileOwner();
    error NonClaimableAchiev();
    error AchievClaimed();

    struct AchievStruct {
        uint256 achievId;
        uint256 requiredAmount;
        bool isMajor;
    }

    address public ProfileContract;
    address public ElementsContract;

    mapping(string => AchievStruct[]) public Achievs;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _profileContract, address _elementsContract) public initializer {
        __ERC1155_init("");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        ProfileContract = _profileContract;
        ElementsContract = _elementsContract;
    }

    function claimLvlAchievs(uint256 profileTokenId) external {
        uint256 userXp = IAlchemistProfile(ProfileContract).getUserXp(profileTokenId, msg.sender);
        AchievStruct[] storage _achievs = Achievs["lvling"];
        _claimAchievs(profileTokenId, _achievs, userXp);
    }

    function claimMergingAchievs(uint256 profileTokenId) external {
        uint256 mergedCount = IAlchemistProfile(ProfileContract).getMergedElementsCount(profileTokenId, msg.sender);
        AchievStruct[] storage _achievs = Achievs["merging"];
        _claimAchievs(profileTokenId, _achievs, mergedCount);
    }

    function claimMorphAchievs(uint256 profileTokenId) external {
        uint256 claimedVolatilesCount =
            IAlchemistProfile(ProfileContract).getClaimedVolatilesCount(profileTokenId, msg.sender);
        AchievStruct[] storage _achievs = Achievs["morphing"];
        _claimAchievs(profileTokenId, _achievs, claimedVolatilesCount);
    }

    function claimMintingAchievs(uint256 profileTokenId) external {
        uint256 totalMinted = IElements(ElementsContract).userTotalMinted(msg.sender);
        AchievStruct[] storage _achievs = Achievs["minting"];
        _claimAchievs(profileTokenId, _achievs, totalMinted);
    }

    function claimDestroyedAchievs(uint256 profileTokenId) external {
        uint256 destroyedElementsCount =
            IAlchemistProfile(ProfileContract).getDestroyedElementsCount(profileTokenId, msg.sender);
        AchievStruct[] storage _achievs = Achievs["destroyed"];
        _claimAchievs(profileTokenId, _achievs, destroyedElementsCount);
    }

    // === admin ===
    function addAchievsCond(string calldata achievType, AchievStruct[] calldata _achievs) external onlyOwner {
        for (uint256 i = 0; i < _achievs.length; i++) {
            Achievs[achievType].push(_achievs[i]);
        }
    }

    // === internal ===
    function _claimAchievs(uint256 profileTokenId, AchievStruct[] memory _achievs, uint256 _requiredAmount) internal {
        if (IERC721AUpgradeable(ProfileContract).ownerOf(profileTokenId) != msg.sender) revert NotProfileOwner();

        if (_requiredAmount == 0) revert NonClaimableAchiev();
        if (_requiredAmount >= 1) {
            uint256 xpCount;
            for (uint256 i = 0; i < _achievs.length; i++) {
                if (_requiredAmount >= _achievs[i].requiredAmount) {
                    xpCount += _achievs[i].isMajor ? 1000 : 200;

                    uint256 _achievId = _achievs[i].achievId;
                    if (balanceOf(msg.sender, _achievId) >= 1) revert AchievClaimed();
                    _mint(msg.sender, _achievId, 1, "");
                }
            }
            if (xpCount == 0) revert NonClaimableAchiev();
            IAlchemistProfile(ProfileContract).addAchievsXp(msg.sender, profileTokenId, xpCount);
        }
    }

    // === overrides ===
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
