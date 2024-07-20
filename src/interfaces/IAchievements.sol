// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IAchievements {
    error NotProfileOwner();
    error NonClaimableAchiev();
    error AchievClaimed();

    struct AchievStruct {
        uint256 achievId;
        uint256 requiredAmount;
        bool isMajor;
    }

    function addAchievsCond(string calldata achievType, AchievStruct[] calldata _achievs) external;
    function claimLvlAchievs(uint256 profileTokenId) external;
    function claimMergingAchievs(uint256 profileTokenId) external;
    function claimMorphAchievs(uint256 profileTokenId) external;
    function claimMintingAchievs(uint256 profileTokenId) external;
    function claimDestroyedAchievs(uint256 profileTokenId) external;
}
