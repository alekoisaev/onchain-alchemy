// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MergeMapSets {
    uint256[] _keys1 = [100, 101];
    uint256[] _aValues = [200, 201, 202];
    uint256[] _bValues = [203, 204, 205];
    uint256[] _cValues = [206, 207, 208];
    uint256[] _percents1 = [80, 10, 10];
    uint256[] _elementTypeIds1 = [1];

    uint256[][6] _set1 = [_keys1, _aValues, _bValues, _cValues, _percents1, _elementTypeIds1];

    // incorrect set for detect error - IncorrectElemenNumber
    uint256[] _keys2 = [99, 1002];
    uint256[] _aValues2 = [200, 201, 202];
    uint256[] _bValues2 = [203, 204, 205];
    uint256[] _cValues2 = [206, 207, 208];
    uint256[] _percents2 = [80, 10, 10];
    uint256[] _elementTypeIds2 = [1];

    uint256[][6] _incorrectSet1 = [_keys2, _aValues2, _bValues2, _cValues2, _percents2, _elementTypeIds2];

    // incorrect set for detect error - IncorrectElemensCount
    uint256[] _keys3 = [100, 101, 103, 104, 105];
    uint256[] _aValues3 = [200];
    uint256[] _bValues3 = [203, 204, 205];
    uint256[] _cValues3 = [206, 207, 208];
    uint256[] _percents3 = [80, 10, 10];
    uint256[] _elementTypeIds3 = [1];

    uint256[][6] _incorrectSet2 = [_keys3, _aValues3, _bValues3, _cValues3, _percents3, _elementTypeIds3];

    // incorrect set for detect error - IncorrectPercentsArrSize
    uint256[] _keys4 = [100, 101, 103];
    uint256[] _aValues4 = [200];
    uint256[] _bValues4 = [203, 204, 205];
    uint256[] _cValues4 = [206, 207, 208];
    uint256[] _percents4 = [70, 10, 10, 10];
    uint256[] _elementTypeIds4 = [1];

    uint256[][6] _incorrectSet3 = [_keys4, _aValues4, _bValues4, _cValues4, _percents4, _elementTypeIds4];

    // incorrect set for detect error - NotEqToHundredPercentsSum
    uint256[] _keys5 = [100, 101, 103];
    uint256[] _aValues5 = [200];
    uint256[] _bValues5 = [203, 204, 205];
    uint256[] _cValues5 = [206, 207, 208];
    uint256[] _percents5 = [70, 30, 10];

    uint256[][6] _incorrectSet4 = [_keys5, _aValues5, _bValues5, _cValues5, _percents5];

    // set with crystals and volatiles
    uint256[] _keys6 = [100, 101, 205, 206];
    uint256[] _aValues6 = [300, 301, 302];
    uint256[] _bValues6 = [303, 304, 305];
    uint256[] _cValues6 = [306, 307, 308];
    uint256[] _percents6 = [20, 70, 10];
    uint256[] _elementTypeIds6 = [1];

    uint256[][6] _volatilesSet1 = [_keys6, _aValues6, _bValues6, _cValues6, _percents6, _elementTypeIds6];

    // set with only A & B, modify=1
    uint256[] _keys7 = [100, 101, 103];
    uint256[] _aValues7 = [200, 201];
    uint256[] _bValues7 = [202, 203, 204];
    uint256[] _cValues7;
    uint256[] _percents7 = [75, 25, 0];
    uint256[] _elementTypeIds7 = [1];

    uint256[][6] _set2 = [_keys7, _aValues7, _bValues7, _cValues7, _percents7, _elementTypeIds7];

    // set with only A, B & C, modify=0
    uint256[] _keys8 = [100, 101, 103];
    uint256[] _aValues8 = [200, 201];
    uint256[] _bValues8;
    uint256[] _cValues8;
    uint256[] _percents8 = [100, 0, 0];
    uint256[] _elementTypeIds8 = [1];

    uint256[][6] _set3 = [_keys8, _aValues8, _bValues8, _cValues8, _percents8, _elementTypeIds8];
}
