// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IElements} from "../interfaces/IElements.sol";
import {IVolatileElements} from "../interfaces/IVolatileElements.sol";
import {IAlchemistProfile} from "../interfaces/IAlchemistProfile.sol";

contract Merging is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    // === ERRORS ===
    error IncorrectElementsCount();
    error IncorrectElementNumber();
    error NotAllowedMergeMapRewrite();
    error IncorrectMergeSet();
    error IncorrectPercentsArrSize();
    error NotEqToHundredPercentsSum();
    error Unauthorized();

    // === CONSTANTS-BITS ===
    uint256 private constant _BITMASK_ELEMENT_ID = (1 << 10) - 1;
    uint256 private constant _BITLENGTH_ELEMENT_ID = 10;
    uint256 private constant _BITMASK_RESULT_PERCENT = (1 << 7) - 1;
    uint256 private constant _BITPOS_RESULT_PERCENT = 90;
    uint256 private constant _BITLENGTH_RESULT_PERCENT = 7;
    uint256 private constant _BITMASK_MODIFY_TYPE_ID = (1 << 3) - 1;
    uint256 private constant _BITPOS_MODIFY = 111;
    uint256 private constant _BITLENGTH_TYPE_ID = 3;
    uint256 private constant _BITPOS_TYPE_ID = 114;

    // === STORAGE ===
    IElements public elementsContract;
    IVolatileElements public volatileContract;
    IAlchemistProfile public profileContract;

    /**
     * Bits Layout: elID~uint10 | Base%~uint7 | Modify~uint2
     *    key:                value:
     * [0..9]    `el1` |  [0..9 | 10..19 | 20..29]         `a1|a2|a3`
     * [10..19]  `el2` |  [30..39 | 40..49 | 50..59]       `b1|b2|b3`
     * [20..29]  `el3` |  [60..69 | 70..79 | 80..89]       `c1|c2|c3`
     * [30..39]  `el4` |  [90..96 | 97..103 | 104..110]    `a%|b%|c%`
     *                 |  [111..113]                       `Modify`
     *                 |  [114..116 | 117..119 | 120..122] `elTypeId - a|b|c`
     */
    mapping(uint256 => uint256) public mergeMap;

    event MergeEvent(
        uint256 profileId,
        uint256[] mergeElements,
        uint256[] resultElements,
        uint256 startIndex,
        uint256 mergeResultCount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    // === MAIN ===

    function merge(uint256 profileId, uint256[] calldata tokenIds) external nonReentrant {
        uint256 tokensLen = tokenIds.length;
        if (tokensLen < 2) revert IncorrectElementsCount();
        if (tokensLen > 4) revert IncorrectElementsCount();

        uint256[] memory elementIds = _getElementIds(tokenIds);

        // uint256 profileLvl = profileContract.getUserLvl(profileId, msg.sender);
        uint256[] memory resultElements = _selectResultArr(profileId, elementIds);

        elementsContract.coreBurnElements(tokenIds);

        uint256 count;
        for (uint256 i; i < resultElements.length;) {
            uint24 resultElementId = uint24(resultElements[i]);
            if (resultElementId > 0) {
                elementsContract.mintElements(msg.sender, resultElementId, 1);

                // add mastery points to profile
                IElements.ElementURIStruct memory _elementURI = elementsContract.elementURI(resultElementId);
                profileContract.addMasteryPoints(
                    msg.sender, profileId, _elementURI.elementTypeId, _elementURI.masteryPoints
                );
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        }

        // add Xp to user's profile
        profileContract.addMergeXp(msg.sender, profileId, elementIds);

        emit MergeEvent(profileId, tokenIds, resultElements, elementsContract.totalMinted() - (count + 1), count);
    }

    function mergeVolatiles(
        uint256 profileId,
        uint256[] calldata elementTokenIds,
        uint256[] calldata volatileTokenIds
    ) external nonReentrant {
        uint256 elementsLen = elementTokenIds.length;
        uint256 tokensLen = elementsLen + volatileTokenIds.length;

        if (tokensLen < 2 && tokensLen > 4) revert IncorrectElementsCount();

        uint256[] memory elementIds = new uint256[](tokensLen);

        for (uint256 i = 0; i < tokensLen;) {
            if (i < elementsLen) {
                if (IERC721AUpgradeable(address(elementsContract)).ownerOf(elementTokenIds[i]) != msg.sender) {
                    revert Unauthorized();
                }
                elementIds[i] = elementsContract.elementId(elementTokenIds[i]);
            } else {
                uint256 index = i - elementsLen;
                if (IERC1155(address(volatileContract)).balanceOf(msg.sender, volatileTokenIds[index]) == 0) {
                    revert Unauthorized();
                }
                elementIds[i] = volatileTokenIds[index];
            }

            unchecked {
                ++i;
            }
        }

        uint256[] memory resultElements =
            _selectResultArr(profileContract.getUserLvl(profileId, msg.sender), elementIds);

        // burning
        elementsContract.coreBurnElements(elementTokenIds);
        volatileContract.burnVolatiles(msg.sender, volatileTokenIds);

        uint256 count;
        for (uint256 i; i < resultElements.length;) {
            uint24 resultElementId = uint24(resultElements[i]);
            if (resultElementId > 0) {
                elementsContract.mintElements(msg.sender, resultElementId, 1);

                // add mastery points to profile
                IElements.ElementURIStruct memory _elementURI = elementsContract.elementURI(resultElementId);
                profileContract.addMasteryPoints(
                    msg.sender, profileId, _elementURI.elementTypeId, _elementURI.masteryPoints
                );

                ++count;
            }
            unchecked {
                ++i;
            }
        }

        // add Xp to user's profile
        profileContract.addMergeXp(msg.sender, profileId, elementIds);

        emit MergeEvent(profileId, elementIds, resultElements, elementsContract.totalMinted() - (count + 1), count);
    }

    /**
     * @dev for front-end - check passed combination can be merged
     */
    function isMergeAllowed(uint256[] memory tokenIds) public view returns (bool) {
        for (uint256 i; i < tokenIds.length;) {
            uint256 elementId = elementsContract.elementId(tokenIds[i]);
            tokenIds[i] = elementId;
            unchecked {
                ++i;
            }
        }
        uint256 key = _packElementBits(tokenIds);

        return mergeMap[key] > 0;
    }

    /**
     * @dev returns mergeMap structured values for front-end
     */
    function getMergeValues(uint256[] calldata elementIds) public view returns (uint256[][] memory) {
        uint256 key = _packElementBits(elementIds);
        uint256 cachedValue = mergeMap[key];

        uint256[][] memory results = new uint256[][](4);

        uint256 startBit = 0;
        for (uint256 i; i < results.length; ++i) {
            results[i] = new uint256[](3);
            for (uint256 j; j < 3; ++j) {
                if (i < 3) {
                    results[i][j] = (cachedValue >> (startBit + j * _BITLENGTH_ELEMENT_ID)) & _BITMASK_ELEMENT_ID;
                } else {
                    results[i][j] = (cachedValue >> (_BITPOS_RESULT_PERCENT + j * _BITLENGTH_RESULT_PERCENT))
                        & _BITMASK_RESULT_PERCENT;
                }
            }
            startBit += 30;
        }

        return results;
    }

    // === ADMIN ===

    /**
     * @dev write merging map - key elements must be in ascending order.
     * @param _elements - look for bits layout at mapping desc.
     */
    function setMergeMap(uint256[][6][] calldata _elements) external onlyOwner {
        for (uint256 i; i < _elements.length;) {
            uint256[][6] calldata _cachedElements = _elements[i];

            uint256 finalKey = _packElementBits(_cachedElements[0]);

            if (mergeMap[finalKey] > 0) revert NotAllowedMergeMapRewrite();

            uint256 packedValue = _packValueBits(
                _cachedElements[1], _cachedElements[2], _cachedElements[3], _cachedElements[4], _cachedElements[5]
            );
            mergeMap[finalKey] = packedValue;

            unchecked {
                ++i;
            }
        }
    }

    function setExternalContracts(
        address _elementsContract,
        address _volatileContract,
        address _profileContract
    ) external onlyOwner {
        elementsContract = IElements(_elementsContract);
        volatileContract = IVolatileElements(_volatileContract);
        profileContract = IAlchemistProfile(_profileContract);
    }

    // === INTERNAL TOOLS ===

    /**
     * @dev get elementId of token
     */
    function _getElementIds(uint256[] calldata tokenIds) internal view returns (uint256[] memory) {
        uint256[] memory elementIds = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length;) {
            if (IERC721AUpgradeable(address(elementsContract)).ownerOf(tokenIds[i]) != msg.sender) {
                revert Unauthorized();
            }

            elementIds[i] = elementsContract.elementId(tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        return elementIds;
    }

    function _getModify(uint256 key) internal view returns (uint256) {
        return mergeMap[key] >> _BITPOS_MODIFY & _BITMASK_MODIFY_TYPE_ID;
    }

    function _selectResultArr(
        uint256 profileId,
        uint256[] memory elementIds
    ) internal view returns (uint256[] memory resultArr) {
        // generate pseudo-random number
        uint256 randomNum =
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))) % 100) * 1e18;

        uint256 key = _packElementBits(elementIds);

        uint256 _cachedValue = mergeMap[key];
        if (_cachedValue <= 0) revert IncorrectMergeSet();

        uint256 modify = _getModify(key);

        (uint256 scaledA, uint256 scaledB) = _calculateScaledPercents(_cachedValue, modify, profileId);
        uint256 startBit = _determineStartBit(randomNum, scaledA, scaledB);

        resultArr = new uint256[](3);
        for (uint256 i; i < 3;) {
            uint256 value = (_cachedValue >> (startBit + i * _BITLENGTH_ELEMENT_ID)) & _BITMASK_ELEMENT_ID;
            if (value > 0) {
                (bool isLimited, uint256 limitCount) = elementsContract.getElementLimits(uint24(value));
                if (isLimited && limitCount == 0) {
                    if (startBit == 30) scaledA += scaledB;
                    if (startBit == 60) scaledA = (100 * 1e18) - (scaledA + scaledB);

                    startBit = _determineStartBit(randomNum, scaledA, scaledB);

                    i = 0;
                }
                resultArr[i] = value;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _determineStartBit(uint256 randomNum, uint256 scaledA, uint256 scaledB) internal pure returns (uint256) {
        if (randomNum <= scaledA) {
            return 0; // result A
        } else if (randomNum <= (scaledA + scaledB)) {
            return 30; // result B
        } else {
            return 60; // result C
        }
    }

    function _calculateScaledPercents(
        uint256 _cachedValue,
        uint256 _modify,
        uint256 profileId
    ) internal view returns (uint256, uint256) {
        uint256 profileLvl = profileContract.getUserLvl(profileId, msg.sender);

        uint256 baseA = (_cachedValue >> (_BITPOS_RESULT_PERCENT)) & _BITMASK_RESULT_PERCENT;
        uint256 baseB = (_cachedValue >> (_BITPOS_RESULT_PERCENT + _BITLENGTH_RESULT_PERCENT)) & _BITMASK_RESULT_PERCENT;
        // uint256 c = (_cachedValue >> (_BITPOS_RESULT_PERCENT + _BITLENGTH_RESULT_PERCENT * 2)) & _BITMASK_RESULT_PERCENT;

        // factor calc
        (int256 a, int256 b) = _calculateFactor(baseB, profileLvl, _modify);

        // uint24 elementTypeId_a = uint24((_cachedValue >> (_BITPOS_TYPE_ID)) & _BITMASK_MODIFY_TYPE_ID);
        uint24 elementTypeId_b =
            uint24((_cachedValue >> (_BITPOS_TYPE_ID + _BITLENGTH_TYPE_ID)) & _BITMASK_MODIFY_TYPE_ID);
        uint24 elementTypeId_c =
            uint24((_cachedValue >> (_BITPOS_TYPE_ID + (_BITLENGTH_TYPE_ID * 2))) & _BITMASK_MODIFY_TYPE_ID);

        // uint256 pointsBonus_a =
        //     elementTypeId_a != 0 ? profileContract.getMasteryPointsBonus(profileId, elementTypeId_a) : 0;
        uint256 pointsBonus_b =
            elementTypeId_b != 0 ? profileContract.getMasteryPointsBonus(profileId, elementTypeId_b) : 0;
        uint256 pointsBonus_c =
            elementTypeId_c != 0 ? profileContract.getMasteryPointsBonus(profileId, elementTypeId_b) : 0;

        /**
         * scale A & B to 1e18 and insert in formula
         * A = BaseA% - factored A;
         * B = BaseB% + factored B;
         */
        uint256 scaledA = uint256(int256((baseA)) * 1e18 - a) - (pointsBonus_b + pointsBonus_c);
        uint256 scaledB = uint256(int256(baseB) * 1e18 + b) + (pointsBonus_c);

        return (scaledA, scaledB);
    }

    function _calculateFactor(
        uint256 baseB,
        uint256 profileLvl,
        uint256 modify
    ) internal pure returns (int256 a, int256 b) {
        if (modify == 0) return (0, 0);

        // Constants
        int256 base = 11 * 1e18; // 11 scaled by 10^18
        int256 divisor = 625 * 1e17; // 62.5 scaled to match 10^18 scaling factor
        int256 Vmid = 20 * 1e18;

        // Vmax calculation = 11 - (%B - 25)^2 / 62.5
        int256 deltaX = (int256(baseB) * 1e18 - 25 * 1e18); // Scale b base percent by 10^18 and subtract 25 (also scaled)
        int256 squaredDeltaX = deltaX * deltaX; // Square deltaX, then scale down to keep result in 10^18 form
        int256 Vmax = base - (squaredDeltaX / divisor); // Adjust formula to maintain precision

        // Factor Calculation = (Vmax * LVL - Vmax) / (Vmid + LVL)
        int256 factorNumerator = Vmax * int256(profileLvl) - Vmax;
        int256 factorDenominator = (Vmid + (int256(profileLvl) * 1e18));

        int256 scaledFactor = (factorNumerator * 1e18) / factorDenominator;

        /**
         * A = Factor * (-1/2 * Modify^2 + 5/2 * Modify)
         * B = Factor * (-3/2 * Modify^2 + 7/2 * Modify)
         * C = Factor * (Modify^2 * Modify)
         *  hardcoded for less calculation
         */
        if (modify == 1) return (scaledFactor * 2, scaledFactor * 2);
        if (modify == 2) return (scaledFactor * 3, scaledFactor);
    }

    /**
     * @dev packing each elementId in uint256 as value for mapping
     * @param a - first set of values
     * @param b - second set of values
     * @param c - third set of values
     * @param percents - percentage for randomness of each set a,b,c
     */
    function _packValueBits(
        uint256[] calldata a,
        uint256[] calldata b,
        uint256[] calldata c,
        uint256[] calldata percents,
        uint256[] calldata elementTypeIds
    ) internal pure returns (uint256 packedValue) {
        uint256[] memory elements = a;

        if (percents.length != 3) revert IncorrectPercentsArrSize();
        if ((percents[0] + percents[1] + percents[2]) != 100) revert NotEqToHundredPercentsSum();
        for (uint256 i; i < 3;) {
            if (i == 0) elements = a;
            if (i == 1) elements = b;
            if (i == 2) elements = c;

            // if (elements.length < 1) revert IncorrectElementsCount();
            if (elements.length > 3) revert IncorrectElementsCount();

            for (uint256 j; j < elements.length;) {
                uint256 _cachedElements = elements[j];

                if (_cachedElements < 100) revert IncorrectElementNumber();
                if (_cachedElements > 999) revert IncorrectElementNumber();

                packedValue |= _cachedElements << ((i * 3 + j) * _BITLENGTH_ELEMENT_ID);

                unchecked {
                    ++j;
                }
            }
            // pack drops percent for each array
            packedValue |= percents[i] << ((_BITLENGTH_RESULT_PERCENT * i) + _BITPOS_RESULT_PERCENT);
            unchecked {
                ++i;
            }
        }

        if (percents[0] == 100) packedValue |= 0 << _BITPOS_MODIFY;
        else if (percents[1] != 0 && percents[2] == 0) packedValue |= 1 << _BITPOS_MODIFY;
        else if (percents[2] != 0) packedValue |= 2 << _BITPOS_MODIFY;

        for (uint256 i = 0; i < elementTypeIds.length;) {
            packedValue |= elementTypeIds[i] << ((_BITLENGTH_TYPE_ID * i) + _BITPOS_TYPE_ID);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev packing each elementId in uint256 as key for mapping
     * @param keyElements - array of elementIds for mergeMap key
     */
    function _packElementBits(uint256[] memory keyElements) internal pure returns (uint256 bitsUint) {
        uint256 length = keyElements.length;

        if (length < 2) revert IncorrectElementsCount();
        if (length > 4) revert IncorrectElementsCount();

        for (uint256 i; i < length;) {
            uint256 _cachedKeyElements = keyElements[i];
            if (_cachedKeyElements < 100) revert IncorrectElementNumber();
            if (_cachedKeyElements > 999) revert IncorrectElementNumber();

            bitsUint |= _cachedKeyElements << (i * _BITLENGTH_ELEMENT_ID);
            unchecked {
                ++i;
            }
        }
    }

    // === override ===
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
