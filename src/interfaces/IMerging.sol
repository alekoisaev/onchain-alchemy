// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IMerging {
    // ---- ERRORS ----
    error IncorrectElementsCount();
    error IncorrectElementNumber();
    error NotAllowedMergeMapRewrite();
    error IncorrectMergeSet();
    error IncorrectPercentsArrSize();
    error NotEqToHundredPercentsSum();
    error Unauthorized();

    event MergeEvent(
        uint256 profileId,
        uint256[] mergeElements,
        uint256[] resultElements,
        uint256 startIndex,
        uint256 mergeResultCount
    );

    function merge(uint256 profileId, uint256[] calldata tokenIds) external;

    function mergeVolatiles(
        uint256 profileId,
        uint256[] calldata elementTokenIds,
        uint256[] calldata volatileTokenIds
    ) external;

    function isMergeAllowed(uint256[] memory tokenIds) external view returns (bool);
}
