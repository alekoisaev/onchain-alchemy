// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import {AlchemistSetup} from "test/utils/ContractsSetup.t.sol";
import {MergeMapSets} from "test/utils/MergeMapArray.sol";

// ---- ERRORS ----
error IncorrectElementsCount();
error IncorrectElementNumber();
error NotAllowedMergeMapRewrite();
error IncorrectMergeSet();
error IncorrectPercentsArrSize();
error NotEqToHundredPercentsSum();
error Unauthorized();
error OwnableUnauthorizedAccount(address);

contract MergingTest is Test, AlchemistSetup, MergeMapSets {
    uint256[][6][] _elementsArray = [_set1];

    uint256[][6][] _elementsArr_IncorrectElementNumber = [_incorrectSet1];
    uint256[][6][] _elementsArr_IncorrectElementsCount = [_incorrectSet2];
    uint256[][6][] _elementsArr_IncorrectPercentsArrSize = [_incorrectSet3];
    uint256[][6][] _elementsArr_NotEqToHundredPercentsSum = [_incorrectSet4];
    uint256[][6][] _elementArr_volatiles = [_volatilesSet1];
    uint256[][6][] _elementsArray2 = [_set2];
    uint256[][6][] _elementsArray3 = [_set3];

    // address public addr1 = makeAddr("addr1");
    // address public addr2 = makeAddr("addr2");
    // address public addr3 = makeAddr("addr3");

    uint256 profileTokenId;

    function setUp() public {
        initializeContracts();

        vm.prank(address(1));
        profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "link");
    }

    function test_SetMergeMap() public {
        // set to merge Contract
        MergingProxy.setMergeMap(_elementsArray);
    }

    function test_SetMergeMap2() public {
        MergingProxy.setMergeMap(_elementsArray2);
    }

    function test_SetMergeMap3() public {
        MergingProxy.setMergeMap(_elementsArray3);
    }

    function testRevert_SetMergeMap_NotAllowedMergeMapRewrite() public {
        // set to merge Contract
        MergingProxy.setMergeMap(_elementsArray);

        vm.expectRevert(NotAllowedMergeMapRewrite.selector);
        MergingProxy.setMergeMap(_elementsArray);
    }

    function testRevert_SetMergeMap_NonOwner() public {
        vm.expectRevert();
        vm.prank(address(1));
        MergingProxy.setMergeMap(_elementsArray);
    }

    function testRevert_SetMergeMap_IncorrectElementNumber() public {
        vm.expectRevert(IncorrectElementNumber.selector);
        MergingProxy.setMergeMap(_elementsArr_IncorrectElementNumber);
    }

    function testRevert_SetMergeMap_IncorrectElementsCount() public {
        vm.expectRevert(IncorrectElementsCount.selector);
        MergingProxy.setMergeMap(_elementsArr_IncorrectElementsCount);
    }

    function testRevert_SetMergeMap_IncorrectPercentsArrSize() public {
        vm.expectRevert(IncorrectPercentsArrSize.selector);
        MergingProxy.setMergeMap(_elementsArr_IncorrectPercentsArrSize);
    }

    function testRevert_SetMergeMap_NotEqToHundredPercentsSum() public {
        vm.expectRevert(NotEqToHundredPercentsSum.selector);
        MergingProxy.setMergeMap(_elementsArr_NotEqToHundredPercentsSum);
    }

    // merging
    function test_Merge() public {
        MergingProxy.setMergeMap(_elementsArray);

        vm.startPrank(address(MergingProxy));

        // mint elements
        ElementsProxy.mintElements(address(1), 100, 1);
        ElementsProxy.mintElements(address(1), 101, 1);

        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        bool isAllowed = MergingProxy.isMergeAllowed(tokenIds);
        assert(isAllowed);

        (,, uint256 Xp,,,,,,,) = AlchemistProfileProxy.profileData(profileTokenId);

        // msg.sender = address 1
        vm.startPrank(address(1));

        MergingProxy.merge(profileTokenId, tokenIds);

        // unset msg.sender as address 1
        vm.stopPrank();

        uint256 balance = ElementsProxy.balanceOf(address(1));
        assertEq(balance, 3);

        assertEq(ElementsProxy.ownerOf(3), address(1));
        assertEq(ElementsProxy.ownerOf(4), address(1));
        assertEq(ElementsProxy.ownerOf(5), address(1));

        uint256[] memory elementIds = new uint256[](2);
        elementIds[0] = 100;
        elementIds[1] = 101;
        uint256 increasedXp = getMergingXp(elementIds);

        assertEq(increasedXp, Xp + increasedXp);
    }

    function test_mergeVolatiles() public {
        MergingProxy.setMergeMap(_elementArr_volatiles);

        // msg.sender = address 1
        vm.startPrank(address(MergingProxy));

        // mint elements
        ElementsProxy.mintElements(address(1), 100, 1); //tokenId 1
        ElementsProxy.mintElements(address(1), 101, 1); //tokenId 2
        // mint volatiles
        vm.startPrank(address(MorphElementsProxy));
        VolatileElementsProxy.mintVolatiles(address(1), 205, 1); // tokenId 205
        VolatileElementsProxy.mintVolatiles(address(1), 206, 1); // tokenId 206

        vm.stopPrank();

        uint256[] memory elementIds = new uint256[](2);
        elementIds[0] = 1;
        elementIds[1] = 2;

        uint256[] memory volatileIds = new uint256[](2);
        volatileIds[0] = 205;
        volatileIds[1] = 206;

        // msg.sender = address 1
        vm.startPrank(address(1));

        MergingProxy.mergeVolatiles(profileTokenId, elementIds, volatileIds);

        // unset msg.sender as address 1
        vm.stopPrank();

        uint256 balance = ElementsProxy.balanceOf(address(1));
        assertEq(balance, 3);

        assertEq(0, VolatileElementsProxy.balanceOf(address(1), 205));
        assertEq(0, VolatileElementsProxy.balanceOf(address(1), 206));

        assertEq(ElementsProxy.ownerOf(3), address(1));
        assertEq(ElementsProxy.ownerOf(4), address(1));
        assertEq(ElementsProxy.ownerOf(5), address(1));
    }

    function testRevert_Merge_NotTokenOwner() public {
        test_SetMergeMap();

        // msg.sender = address 1
        vm.startPrank(address(MergingProxy));

        // mint elements
        ElementsProxy.mintElements(address(2), 100, 1);
        ElementsProxy.mintElements(address(2), 101, 1);

        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        vm.expectRevert(Unauthorized.selector);
        // msg.sender = address 1
        vm.prank(address(1));
        MergingProxy.merge(profileTokenId, tokenIds);
    }

    function testRevert_Merge_IncorrectMergeSet() public {
        // msg.sender = address 1
        vm.startPrank(address(MergingProxy));

        // mint elements
        ElementsProxy.mintElements(address(1), 100, 1);
        ElementsProxy.mintElements(address(1), 101, 1);

        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        vm.prank(address(1));
        vm.expectRevert(IncorrectMergeSet.selector);
        MergingProxy.merge(profileTokenId, tokenIds);
    }

    function testRevert_Merge_IncorrectElementsCount() public {
        test_SetMergeMap();

        vm.startPrank(address(MergingProxy));

        // mint elements
        ElementsProxy.mintElements(address(1), 100, 10);
        ElementsProxy.mintElements(address(1), 101, 1);

        // less than 2
        uint256[] memory tokenIds_one = new uint256[](1);
        tokenIds_one[0] = 1;

        // msg.sender = address 0x1
        vm.startPrank(address(1));

        vm.expectRevert(IncorrectElementsCount.selector);
        MergingProxy.merge(profileTokenId, tokenIds_one);

        // more than 4
        uint256[] memory tokenIds_two = new uint256[](5);
        tokenIds_two[0] = 1;
        tokenIds_two[1] = 2;
        tokenIds_two[2] = 3;
        tokenIds_two[3] = 4;
        tokenIds_two[4] = 11;

        vm.expectRevert(IncorrectElementsCount.selector);
        MergingProxy.merge(profileTokenId, tokenIds_two);

        // unset msg.sender as address 0x1
        vm.stopPrank();
    }

    function test_IsMergeAllowed() public {
        test_SetMergeMap();

        // msg.sender = address 1
        vm.startPrank(address(MergingProxy));

        // mint elements
        ElementsProxy.mintElements(address(1), 100, 1);
        ElementsProxy.mintElements(address(1), 101, 1);
        // unset msg.sender as address 1
        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        bool mergeAllowed = MergingProxy.isMergeAllowed(tokenIds);
        assert(mergeAllowed);

        tokenIds[0] = 2;
        tokenIds[1] = 1;

        bool mergeNotAllowed = MergingProxy.isMergeAllowed(tokenIds);
        assert(!mergeNotAllowed);
    }

    function test_getMergeValues() public {
        MergingProxy.setMergeMap(_elementsArray3);

        uint256[] memory elementIds = new uint256[](3);
        elementIds[0] = 100;
        elementIds[1] = 101;
        elementIds[2] = 103;

        uint256[][] memory mergeMapValues = MergingProxy.getMergeValues(elementIds);

        for (uint256 i = 0; i < mergeMapValues.length; i++) {
            emit log_array(mergeMapValues[i]);
        }
    }

    // utils

    function getMergingXp(uint256[] memory elementIds) internal pure returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < elementIds.length; i++) {
            total += elementIds[i];
        }

        return total / 4;
    }

    // function addLvlingData() internal {
    //     uint256[] memory lvls = new uint256[](10);
    //     uint256[] memory xps = new uint256[](10);

    //     lvls[0] = 1;
    //     xps[0] = 0;

    //     lvls[1] = 2;
    //     xps[1] = 230;

    //     lvls[2] = 3;
    //     xps[2] = 250;

    //     lvls[3] = 4;
    //     xps[3] = 275;

    //     lvls[4] = 5;
    //     xps[4] = 300;

    //     lvls[5] = 6;
    //     xps[5] = 325;

    //     lvls[6] = 7;
    //     xps[6] = 355;

    //     lvls[7] = 8;
    //     xps[7] = 385;

    //     lvls[8] = 9;
    //     xps[8] = 420;

    //     lvls[9] = 10;
    //     xps[9] = 455;

    //     AlchemistProfileProxy.setLvlData(lvls, xps);
    // }
}
