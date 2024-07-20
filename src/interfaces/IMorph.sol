// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IMorphElements {
    error NonExistingMorphPool();
    error NotTokenOwner();
    error NonExistingPoolOrElementId();
    error TokenMorphed();
    error TokenNotMorphed();
    error BurnableTokensCountExceeded();
    error NoReward();

    struct MorphData {
        uint64 lastMorphTime;
        uint64 lastClaimTime;
        uint256 userMorphedTokensCount;
        uint256 userRate;
    }

    struct MorphPoolMapStruct {
        uint24 rewardElementId;
        uint256 morphedElementsCount;
    }

    /**
     * @dev return element staking status
     */
    function isElementMorphed(uint256 tokenId) external view returns (bool);

    // === EVENTS ===
    event ElementsMorphed(address staker, uint256 stakingElementId, uint256[] tokenIds);
    event ElementsUnMorphed(address staker, uint256 stakingElementId, uint256[] tokenIds);
    event ClaimVolatile(address staker, uint256 rewardTokenCount, uint256 rewardElementId);
    event RewardUpdate(uint256 periodTime, uint256 baseRate, uint256 baseRateMax, uint256 km, uint256 maxRewardCount);
}
