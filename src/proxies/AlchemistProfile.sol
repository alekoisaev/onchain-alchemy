// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {IElements} from "../interfaces/IElements.sol";

contract AlchemistProfile is ERC721AUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    error Unauthorized();
    error NonProfileOwner();
    error NonElementOwner();
    error NameAlreadyExists();

    struct ProfileDataStruct {
        string name;
        string avatarLink;
        uint256 Xp;
        // stats for calculations
        uint256 mintedElementsCount;
        uint256 mergedElementsCount;
        uint256 claimedVolatilesCount;
        uint256 destroyedElementsCountBook1;
        uint256 destroyedElementsCountBook2;
        uint256 destroyedElementsCountBook3;
        uint256 destroyedElementsCountBook4;
    }

    struct ProfilePointsStruct {
        uint256 baseMasteryPoints;
        uint256 activeElementTokenId;
    }

    // === vars ===
    address public ElementsContract;
    address public MergeContract;
    address public MorphContract;
    address public AchievsContract;

    mapping(uint256 => ProfileDataStruct) public profileData;
    mapping(string => uint256) nameToProfileId;

    /// Fire - 1 | Water - 2 | Air - 3 | Earth - 4 | Arcane - 5
    /// profileTokenId => elementTypeId => ProfilePointsStruct
    mapping(uint256 => mapping(uint24 => ProfilePointsStruct)) public ProfileMasteryPoints;

    // lvl => required Xp
    mapping(uint256 => uint256) public levelData;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer initializerERC721A {
        __ERC721A_init("Alchemist Profile", "ALCHPRFL");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    modifier onlyProfileOwner(address profileOwner, uint256 profileTokenId) {
        if (ownerOf(profileTokenId) != profileOwner) revert NonProfileOwner();
        _;
    }

    // === Main ===

    function createProfile(string calldata profileName, string calldata _avatarLink) external returns (uint256) {
        if (nameToProfileId[profileName] != 0) revert NameAlreadyExists();

        uint256 tokenId = _nextTokenId();
        nameToProfileId[profileName] = tokenId;
        ProfileDataStruct storage _profileData = profileData[tokenId];

        _profileData.name = profileName;
        _profileData.avatarLink = _avatarLink;

        _mint(msg.sender, 1);

        return tokenId;
    }

    function setMasteryElements(
        uint256 profileTokenId,
        uint256[] calldata tokenIds
    ) external onlyProfileOwner(msg.sender, profileTokenId) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 elementTokenId = tokenIds[i];
            if (IERC721AUpgradeable(ElementsContract).ownerOf(elementTokenId) != msg.sender) revert NonElementOwner();

            uint24 elementTypeId = IElements(ElementsContract).elementTypeId(elementTokenId);
            ProfileMasteryPoints[profileTokenId][elementTypeId].activeElementTokenId = elementTokenId;
            IElements(ElementsContract).setMasteryActiveElement(elementTokenId, true);
        }
    }

    function unsetMasteryElements(
        uint256 profileTokenId,
        uint256[] calldata tokenIds
    ) external onlyProfileOwner(msg.sender, profileTokenId) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 elementTokenId = tokenIds[i];
            if (IERC721AUpgradeable(ElementsContract).ownerOf(elementTokenId) != msg.sender) revert NonElementOwner();

            uint24 elementTypeId = IElements(ElementsContract).elementTypeId(elementTokenId);
            ProfileMasteryPoints[profileTokenId][elementTypeId].activeElementTokenId = 0;
            IElements(ElementsContract).setMasteryActiveElement(elementTokenId, false);
        }
    }

    function changeName(
        uint256 profileTokenId,
        string calldata profileName
    ) external onlyProfileOwner(msg.sender, profileTokenId) {
        if (nameToProfileId[profileName] != 0) revert NameAlreadyExists();

        ProfileDataStruct storage _profileData = profileData[profileTokenId];
        nameToProfileId[_profileData.name] = 0;
        nameToProfileId[profileName] = profileTokenId;

        _profileData.name = profileName;
    }

    function changeAvatar(
        uint256 profileTokenId,
        string calldata _avatarLink
    ) external onlyProfileOwner(msg.sender, profileTokenId) {
        profileData[profileTokenId].avatarLink = _avatarLink;
    }

    function changeNameAvatar(
        uint256 profileTokenId,
        string calldata profileName,
        string calldata _avatarLink
    ) external onlyProfileOwner(msg.sender, profileTokenId) {
        if (nameToProfileId[profileName] != 0) revert NameAlreadyExists();

        ProfileDataStruct storage _profileData = profileData[profileTokenId];

        nameToProfileId[_profileData.name] = 0;
        nameToProfileId[profileName] = profileTokenId;

        _profileData.name = profileName;
        _profileData.avatarLink = _avatarLink;
    }

    // === XP & point external contracts ===
    function addMasteryPoints(
        address profileOwner,
        uint256 profileTokenId,
        uint24 elementTypeId,
        uint256 masteryPoints
    ) external onlyProfileOwner(profileOwner, profileTokenId) {
        if (msg.sender != MergeContract) revert Unauthorized();

        ProfileMasteryPoints[profileTokenId][elementTypeId].baseMasteryPoints += masteryPoints;
    }

    function addMergeXp(
        address profileOwner,
        uint256 profileTokenId,
        uint256[] calldata elementIds
    ) external onlyProfileOwner(profileOwner, profileTokenId) {
        if (msg.sender != MergeContract) revert Unauthorized();

        uint256 addedXp = _getMergeXp(elementIds);
        profileData[profileTokenId].Xp += addedXp;
        profileData[profileTokenId].mergedElementsCount += 1;

        uint256 bookNumber = IElements(ElementsContract).bookNumber();
        if (bookNumber == 1) profileData[profileTokenId].destroyedElementsCountBook1 += elementIds.length;
        else if (bookNumber == 2) profileData[profileTokenId].destroyedElementsCountBook2 += elementIds.length;
        else if (bookNumber == 3) profileData[profileTokenId].destroyedElementsCountBook3 += elementIds.length;
        else if (bookNumber == 4) profileData[profileTokenId].destroyedElementsCountBook4 += elementIds.length;
    }

    function addMorphingXp(
        address profileOwner,
        uint256 profileTokenId,
        uint256 claimedRewardCount
    ) external onlyProfileOwner(profileOwner, profileTokenId) {
        if (msg.sender != MorphContract) revert Unauthorized();

        uint256 addedXp = _getMorphXp(claimedRewardCount);
        profileData[profileTokenId].Xp += addedXp;
        profileData[profileTokenId].claimedVolatilesCount += claimedRewardCount;
    }

    function addAchievsXp(
        address profileOwner,
        uint256 profileTokenId,
        uint256 xpCount
    ) external onlyProfileOwner(profileOwner, profileTokenId) {
        if (msg.sender != AchievsContract) revert Unauthorized();

        profileData[profileTokenId].Xp += xpCount;
    }

    // === view ===
    function getMasteryPointsBonus(
        uint256 profileTokenId,
        uint24 elementTypeId
    ) external view returns (uint256 finalBonus) {
        ProfilePointsStruct memory masteryPointsData = ProfileMasteryPoints[profileTokenId][elementTypeId];
        uint256 baseMasteryPoints = masteryPointsData.baseMasteryPoints;
        uint256 activeElementTokenId = masteryPointsData.activeElementTokenId;

        if (baseMasteryPoints == 0) return 0;

        uint256 activeElementBonus = activeElementTokenId != 0
            ? IElements(ElementsContract).elementURI(uint24(IElements(ElementsContract).elementId(activeElementTokenId)))
                .masteryBonus
            : 0;

        uint256 totalPoints = baseMasteryPoints + activeElementBonus;

        /// Vmax * totalPoints / Vmid + totalPoints;
        /// hardcoded for less memory use
        finalBonus = ((30 * 1e18) * (totalPoints * 1e18)) / ((2000 * 1e18) + (totalPoints * 1e18));
    }

    function getUserXp(
        uint256 profileTokenId,
        address profileOwner
    ) public view onlyProfileOwner(profileOwner, profileTokenId) returns (uint256) {
        return profileData[profileTokenId].Xp;
    }

    function getUserLvl(uint256 profileTokenId, address profileOwner) public view returns (uint256) {
        uint256 userXp = getUserXp(profileTokenId, profileOwner);

        uint256 lvl = 1;
        while (true) {
            uint256 xp = levelData[lvl + 1];
            if (xp == 0) break;
            if (userXp < xp) break;
            else lvl++;
        }
        return lvl;
    }

    // for front-end...
    function isNameExists(string calldata profileName) public view returns (bool) {
        return nameToProfileId[profileName] == 0 ? true : false;
    }

    function getMergedElementsCount(
        uint256 profileTokenId,
        address profileOwner
    ) public view onlyProfileOwner(profileOwner, profileTokenId) returns (uint256) {
        return profileData[profileTokenId].mergedElementsCount;
    }

    function getClaimedVolatilesCount(
        uint256 profileTokenId,
        address profileOwner
    ) public view onlyProfileOwner(profileOwner, profileTokenId) returns (uint256) {
        return profileData[profileTokenId].claimedVolatilesCount;
    }

    function getDestroyedElementsCount(
        uint256 profileTokenId,
        address profileOwner
    ) public view onlyProfileOwner(profileOwner, profileTokenId) returns (uint256) {
        ProfileDataStruct storage _profileData = profileData[profileTokenId];

        return _profileData.destroyedElementsCountBook1 + _profileData.destroyedElementsCountBook2
            + _profileData.destroyedElementsCountBook3 + _profileData.destroyedElementsCountBook4;
    }

    function getProfileData(uint256 profileTokenId) public view returns (ProfileDataStruct memory) {
        return profileData[profileTokenId];
    }

    function _getMergeXp(uint256[] calldata elementIds) internal pure returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < elementIds.length; i++) {
            total += elementIds[i];
        }

        return total / 4;
    }

    function _getMorphXp(uint256 claimedRewardCount) internal pure returns (uint256) {
        return claimedRewardCount * 100;
    }

    // === admin ===
    function setExternalContracts(
        address _elementsContract,
        address _mergeContract,
        address _morphContract,
        address _achievsContract
    ) external onlyOwner {
        ElementsContract = _elementsContract;
        MergeContract = _mergeContract;
        MorphContract = _morphContract;
        AchievsContract = _achievsContract;
    }

    /**
     * @dev lvls items must be in ascending order
     */
    function setLvlData(uint256[] calldata lvls, uint256[] calldata xps) external onlyOwner {
        if (lvls.length != xps.length) revert();

        for (uint256 i = 0; i < lvls.length; i++) {
            levelData[lvls[i]] = xps[i];
        }
    }

    // === overrides ===
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
