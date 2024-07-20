// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";
import {AlchemistSetup} from "test/utils/ContractsSetup.t.sol";

error IncorrectElementId();
error NonEqualArrays();
error TokenStaked();
error ElementLimitReached();
error TokenMasteryLocked();
error NonElementOwner();

contract ElementsTest is Test, AlchemistSetup {
    uint256[2][] limits;

    bytes32 public constant MERGE_CONTRACT_ROLE = keccak256("MERGE");
    bytes32 public constant MORPH_CONTRACT_ROLE = keccak256("MORPH");
    bytes32 public constant MINTER_CONTRACT_ROLE = keccak256("SALE");

    function setUp() public {
        initializeContracts();
    }

    function test_MintedElementId(uint24 elementId) public {
        vm.assume(elementId > 100 && elementId < 999);

        vm.prank(address(MergingProxy));
        ElementsProxy.mintElements(msg.sender, elementId, 1);
        assertEq(ElementsProxy.elementId(1), elementId);
    }

    function test_MintElements(uint256 count) public {
        vm.assume(count > 0 && count < 100);

        vm.prank(address(MergingProxy));

        ElementsProxy.mintElements(msg.sender, 100, count);
        assertEq(ElementsProxy.balanceOf(msg.sender), count);
    }

    function test_BatchMintElements() public {
        vm.startPrank(address(MintingContract));

        uint24[] memory elementIds = new uint24[](2);
        elementIds[0] = 100;
        elementIds[1] = 101;

        uint256[] memory elementCounts = new uint256[](2);
        elementCounts[0] = 2;
        elementCounts[1] = 3;

        ElementsProxy.batchMintElements(msg.sender, elementIds, elementCounts);

        assertEq(ElementsProxy.balanceOf(msg.sender), 5);

        assertEq(ElementsProxy.elementId(1), 100);
        assertEq(ElementsProxy.elementId(2), 100);
        assertEq(ElementsProxy.elementId(3), 101);
        assertEq(ElementsProxy.elementId(4), 101);
        assertEq(ElementsProxy.elementId(5), 101);
    }

    function test_tokenURI() public {
        vm.prank(address(MergingProxy));

        ElementsProxy.mintElements(msg.sender, 100, 1);

        ///
        uint256[2][] memory elementLimits = new uint256[2][](1);
        elementLimits[0] = [uint256(100), uint256(100)];
        ElementsProxy.setElementLimits(elementLimits);
        ///

        ///
        uint24[] memory elementIds = new uint24[](1);
        uint24[] memory typeIds = new uint24[](1);
        uint256[] memory masteryPoints = new uint256[](1);
        uint256[] memory masteryBonuses = new uint256[](1);
        string[] memory elementNames = new string[](1);

        elementIds[0] = 100;
        typeIds[0] = 1;
        masteryPoints[0] = 0;
        masteryBonuses[0] = 0;
        elementNames[0] = "Fire";
        ElementsProxy.setElementURIs(elementIds, typeIds, masteryPoints, masteryBonuses, elementNames);
        ///

        ///
        string memory tokenUri = ElementsProxy.tokenURI(1);

        emit log_string(tokenUri);
    }

    // function test_BatchMintElements_NonEqualArrays(uint24[] memory elementIds, uint256[] memory elementCounts) public {
    //     vm.assume(elementIds.length != elementCounts.length);

    //     vm.startPrank(address(MintingContract));

    //     vm.expectRevert(NonEqualArrays.selector);
    //     ElementsProxy.batchMintElements(msg.sender, elementIds, elementCounts);
    // }
    function test_ElementTransfer() public {
        vm.startPrank(address(MergingProxy));
        ElementsProxy.mintElements(address(1), 100, 1);
        ElementsProxy.mintElements(address(1), 101, 1);
        vm.stopPrank();

        vm.startPrank(address(1));
        uint256 profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        // set mastery element and transfer
        AlchemistProfileProxy.setMasteryElements(profileTokenId, tokenIds);

        vm.expectRevert(TokenMasteryLocked.selector);
        ElementsProxy.transferFrom(address(1), address(2), 1);

        ElementsProxy.transferFrom(address(1), address(2), 2);

        // unset mastery element
        AlchemistProfileProxy.unsetMasteryElements(profileTokenId, tokenIds);
        ElementsProxy.transferFrom(address(1), address(2), 1);

        tokenIds[0] = 2;
        vm.expectRevert(NonElementOwner.selector);
        AlchemistProfileProxy.setMasteryElements(profileTokenId, tokenIds);
    }

    function test_MintElements_IncorrectElementId(uint24 elementId) public {
        vm.assume(elementId < 100 || elementId > 999);

        vm.startPrank(address(MergingProxy));

        vm.expectRevert(IncorrectElementId.selector);
        ElementsProxy.mintElements(msg.sender, elementId, 10);
    }

    function test_MintElements_ElementLimitReached(uint24 elementId, uint256 count) public {
        vm.assume((elementId > 100 && elementId < 999) && count > 0 && count < 100);

        limits.push([uint256(elementId), 25]);

        ElementsProxy.setElementLimits(limits);

        if (count > 25) {
            vm.expectRevert(ElementLimitReached.selector);
        }

        vm.startPrank(address(MergingProxy));
        ElementsProxy.mintElements(msg.sender, elementId, count);
    }

    function test_setApprove(address trueAddr, address falseAddr) public {
        vm.assume(trueAddr != address(0) && falseAddr != address(0));
        vm.assume(trueAddr != falseAddr);

        vm.prank(trueAddr);
        ElementsProxy.setUserApprovePass();

        bool isApproved = ElementsProxy.isApprovedPass(trueAddr);
        assertEq(isApproved, true);

        bool notApproved = ElementsProxy.isApprovedPass(falseAddr);
        assertEq(notApproved, false);
    }

    function test_hasRoles() public {
        bool hasMinterRole = ElementsProxy.hasRole(MINTER_CONTRACT_ROLE, address(MintingContract));
        bool hasMergeRole = ElementsProxy.hasRole(MERGE_CONTRACT_ROLE, address(MergingProxy));
        bool hasMorphRole = ElementsProxy.hasRole(MORPH_CONTRACT_ROLE, address(MorphElementsProxy));

        assert(hasMinterRole);
        assert(hasMergeRole);
        assert(hasMorphRole);
    }
}
