// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";

import {IElements} from "../interfaces/IElements.sol";
import {IVolatileElements} from "../interfaces/IVolatileElements.sol";
import {IAlchemistProfile} from "../interfaces/IAlchemistProfile.sol";

contract MorphElements is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using LibBitmap for LibBitmap.Bitmap;

    // === ERRORS ===
    error NonExistingMorphPool();
    error NotTokenOwner();
    error NonExistingPoolOrElementId();
    error TokenMorphed();
    error TokenNotMorphed();
    error BurnableTokensCountExceeded();
    error NoReward();

    // === STRUCTS ===
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

    // === STORAGE ===
    IElements public elementsContract;
    IVolatileElements public rewardContract;
    IAlchemistProfile public profileContract;

    mapping(address => mapping(uint24 => MorphData)) public morphInfo;
    mapping(uint24 => MorphPoolMapStruct) public morphingPool;
    LibBitmap.Bitmap private _morphedTokenState;

    // === VARS ===
    uint256 periodTime;
    uint256 baseRate;
    uint256 baseRateMax;
    uint256 km;
    uint256 maxRewardCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        periodTime = 1 minutes; // 24 hours - rewardTokenCount per timePerReward
        baseRate = 2;
        baseRateMax = 8;
        km = 75;
        maxRewardCount = 5;
    }

    // === MAIN ===
    function morphToVolatile(uint24 _elementId, uint256[] calldata tokenIds) external nonReentrant {
        MorphData storage _morphInfo = morphInfo[msg.sender][_elementId];
        MorphPoolMapStruct storage _morphingPool = morphingPool[_elementId];

        if (_morphingPool.rewardElementId <= 0) revert NonExistingMorphPool();

        uint256 tokensCount = tokenIds.length;
        for (uint256 i; i < tokensCount;) {
            uint256 _cachedTokenId = tokenIds[i];

            if (IERC721AUpgradeable(address(elementsContract)).ownerOf(_cachedTokenId) != msg.sender) {
                revert NotTokenOwner();
            }
            if (elementsContract.elementId(_cachedTokenId) != _elementId) revert NonExistingPoolOrElementId();
            if (_morphedTokenState.get(_cachedTokenId)) revert TokenMorphed();

            _morphedTokenState.set(_cachedTokenId);
            unchecked {
                ++i;
            }
        }

        // current Rate for user at the morphing moment
        uint256 _morphedElementsCount = _morphingPool.morphedElementsCount;
        _morphInfo.userRate = baseRate + (baseRateMax * _morphedElementsCount) / (km + _morphedElementsCount);

        _morphInfo.lastMorphTime = uint64(block.timestamp);
        unchecked {
            _morphInfo.userMorphedTokensCount += tokensCount;
            _morphingPool.morphedElementsCount += tokensCount;
        }

        emit ElementsMorphed(msg.sender, _elementId, tokenIds);
    }

    function unMorphElements(
        uint256 profileTokenId,
        uint24 _elementId,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        MorphData storage _morphInfo = morphInfo[msg.sender][_elementId];
        MorphPoolMapStruct storage _morphingPool = morphingPool[_elementId];

        uint256 tokensCount = tokenIds.length;
        for (uint256 i; i < tokensCount;) {
            uint256 _cachedTokenId = tokenIds[i];

            if (IERC721AUpgradeable(address(elementsContract)).ownerOf(_cachedTokenId) != msg.sender) {
                revert NotTokenOwner();
            }
            if (elementsContract.elementId(_cachedTokenId) != _elementId) revert NonExistingPoolOrElementId();
            if (!_morphedTokenState.get(_cachedTokenId)) revert TokenNotMorphed();

            _morphedTokenState.unset(_cachedTokenId);

            unchecked {
                ++i;
            }
        }

        uint256 _rewardCount = claimVolatile(msg.sender, _elementId);
        if (tokensCount > (_rewardCount * _morphInfo.userRate)) revert BurnableTokensCountExceeded();

        _morphInfo.userMorphedTokensCount -= tokensCount;
        _morphingPool.morphedElementsCount -= tokensCount;

        // burning elements
        elementsContract.coreBurnElements(tokenIds);
        // add Xp to user's profile
        profileContract.addMorphingXp(msg.sender, profileTokenId, _rewardCount);

        emit ElementsUnMorphed(msg.sender, _elementId, tokenIds);
    }

    // === internal tools ===
    function claimVolatile(address morpher, uint24 morphedElementId) internal returns (uint256 rewardCount) {
        uint24 rewardElement = morphingPool[morphedElementId].rewardElementId;

        rewardCount = calculateReward(morpher, morphedElementId);
        if (rewardCount == 0) revert NoReward();
        morphInfo[morpher][morphedElementId].lastClaimTime = uint64(block.timestamp);
        rewardContract.mintVolatiles(morpher, rewardElement, rewardCount);
        emit ClaimVolatile(morpher, rewardCount, rewardElement);
    }

    function calculateReward(address morpher, uint24 morphedElementId) public view returns (uint256) {
        MorphData storage morphData = morphInfo[morpher][morphedElementId];

        uint256 passedTimeFromMorph = block.timestamp - morphData.lastMorphTime;

        uint256 totalPeriods = passedTimeFromMorph / periodTime;

        uint256 currentRate = 0;
        if ((passedTimeFromMorph) >= periodTime) {
            if ((block.timestamp - morphData.lastClaimTime) >= periodTime) {
                currentRate = morphData.userRate;
            }
        }

        uint256 userMaxReward;
        if (currentRate > 0) userMaxReward = (morphData.userMorphedTokensCount / currentRate);

        if (totalPeriods >= maxRewardCount) {
            return maxRewardCount;
        }
        if (totalPeriods > userMaxReward) {
            return userMaxReward;
        }
        return totalPeriods;
    }

    // === view ===
    function isElementMorphed(uint256 tokenId) external view returns (bool) {
        return _morphedTokenState.get(tokenId);
    }

    // === admin ===
    function setExternalContracts(
        address _elementsContract,
        address _rewardContract,
        address _profileContract
    ) external onlyOwner {
        elementsContract = IElements(_elementsContract);
        rewardContract = IVolatileElements(_rewardContract);
        profileContract = IAlchemistProfile(_profileContract);
    }

    function updateReward(
        uint256 _baseRate,
        uint256 _baseRateMax,
        uint256 _km,
        uint256 _periodTime,
        uint256 _maxRewardCount
    ) external onlyOwner {
        periodTime = _periodTime;
        baseRate = _baseRate;
        baseRateMax = _baseRateMax;
        km = _km;
        maxRewardCount = _maxRewardCount;

        emit RewardUpdate(_periodTime, _baseRate, _baseRateMax, _km, _maxRewardCount);
    }

    // [[stake elementId, result elementId], [...]]
    function setMorphMap(uint24[2][] calldata elements) external onlyOwner {
        for (uint256 i; i < elements.length;) {
            // cache array
            uint24[2] calldata _elements = elements[i];
            // stakeMap[uint24(_cachedElements[0])] = _cachedElements[1];
            morphingPool[_elements[0]].rewardElementId = _elements[1];
            unchecked {
                ++i;
            }
        }
    }

    // === override ===
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // === EVENTS ===
    event ElementsMorphed(address staker, uint256 stakingElementId, uint256[] tokenIds);
    event ElementsUnMorphed(address staker, uint256 stakingElementId, uint256[] tokenIds);
    event ClaimVolatile(address staker, uint256 rewardTokenCount, uint256 rewardElementId);
    event RewardUpdate(uint256 periodTime, uint256 baseRate, uint256 baseRateMax, uint256 km, uint256 maxRewardCount);
}
