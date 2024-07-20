// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IElements {
    error Unauthorized(address sender);
    error IncorrectElementId();
    error NonEqualArrays();
    error TokenMorphed();
    error NotAuthorized();
    error ElementLimitReached();
    error NotWhitelisted();

    struct RareElementLimits {
        uint256 limit;
        bool isLimitedElement;
    }

    struct ElementURIStruct {
        // ...
        uint24 elementTypeId;
        uint256 masteryPoints;
        uint256 masteryBonus;
    }

    /**
     * @dev batch minting
     */
    function batchMintElements(address receiver, uint24[] calldata _elementIds, uint256[] calldata counts) external;

    /**
     * @dev Mint function with setting _elementId in erc721a extraData slot.
     */
    function mintElements(address to, uint24 _elementId, uint256 count) external;

    /**
     * @dev tokens bunring without ownership validating for Merge and Morph contracts.
     */
    function coreBurnElements(uint256[] calldata tokenIds) external;

    function burnElements(uint256[] calldata tokenIds) external;

    function setUserApprovePass() external;

    function setMasteryActiveElement(uint256 tokenId, bool lock) external;

    function isApprovedPass(address sender) external view returns (bool);

    function bookNumber() external view returns (uint256);

    /**
     * @dev returns elementId of token from extraData slot.
     */
    function elementId(uint256 tokenId) external view returns (uint256);

    /**
     * @dev returns elementTypeId of token
     */
    function elementTypeId(uint256 tokenId) external view returns (uint24);

    /**
     * @dev returns ElementURIStruct of elementId
     */
    function elementURI(uint24 elementId) external view returns (ElementURIStruct memory);

    /**
     * @dev return totalMinted tokens count
     */
    function totalMinted() external view returns (uint256);

    /**
     * @dev return total minted tokens count by address.
     */
    function userTotalMinted(address owner) external view returns (uint256);

    /**
     * @dev return mintable count of elementId
     */
    function getElementLimits(uint24 _elementId) external view returns (bool, uint256);
}
