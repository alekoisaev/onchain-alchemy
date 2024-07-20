// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IAlchemistProfile {
    error Unauthorized();
    error NonProfileOwner();
    error NonElementOwner();

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

    function createProfile(string calldata profileName, string calldata _avatarLink) external returns (uint256);

    function addMasteryPoints(
        address profileOwner,
        uint256 profileTokenId,
        uint24 elementTypeId,
        uint256 masteryPoints
    ) external;
    function addMergeXp(address profileOwner, uint256 tokenId, uint256[] calldata elementIds) external;
    function addMorphingXp(address profileOwner, uint256 profileTokenId, uint256 claimedRewardsCount) external;
    function addAchievsXp(address profileOwner, uint256 profileTokenId, uint256 xpCount) external;
    function getMasteryPointsBonus(
        uint256 profileTokenId,
        uint24 elementTypeId
    ) external view returns (uint256 finalBonus);
    function getUserXp(uint256 profileTokenId, address profileOwner) external view returns (uint256);
    function getUserLvl(uint256 profileTokenId, address profileOwner) external view returns (uint256);
    function getMergedElementsCount(uint256 profileTokenId, address profileOwner) external view returns (uint256);
    function getClaimedVolatilesCount(uint256 profileTokenId, address profileOwner) external view returns (uint256);
    function getDestroyedElementsCount(uint256 profileTokenId, address profileOwner) external view returns (uint256);
}
