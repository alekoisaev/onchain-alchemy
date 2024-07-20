// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AlchemistSetup} from "test/utils/ContractsSetup.t.sol";

error NonExistingMorphPool();
error NotTokenOwner();
error NonExistingPoolOrElementId();
error TokenMorphed();
error TokenNotMorphed();
error BurnableTokensCountExceeded();
error NoReward();

contract MorphElementsTest is Test, AlchemistSetup {
    uint24[2][] public morphMap = new uint24[2][](2);

    address public addr1 = makeAddr("addr1");
    address public addr2 = makeAddr("addr2");
    address public addr3 = makeAddr("addr3");

    uint256 periodTime = 1 minutes; // 24 hours - rewardTokenCount per timePerReward
    uint256 baseRate = 2;
    uint256 baseRateMax = 8;
    uint256 km = 75;
    uint256 maxRewardCount = 5;

    uint256 profileTokenId;

    function setUp() public {
        initializeContracts();

        vm.prank(addr1);
        profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "link");
    }

    function test_SetMorphMap() public {
        morphMap.push([100, 201]);
        morphMap.push([101, 202]);

        MorphElementsProxy.setMorphMap(morphMap);

        (uint24 rewardElementId1,) = MorphElementsProxy.morphingPool(100);
        assertEq(rewardElementId1, 201);

        (uint24 rewardElementId2,) = MorphElementsProxy.morphingPool(101);
        assertEq(rewardElementId2, 202);
    }

    // === morphing ===

    function test_morphToVolatile(uint256 tokensCount) public {
        vm.assume(tokensCount > 0 && tokensCount < 1000);

        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 100, tokensCount);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), tokensCount);

        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        // ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(1);
        MorphElementsProxy.morphToVolatile(100, tokenIds);

        // assert all states changed in staking function.
        // isMorphed
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bool isMorphed = MorphElementsProxy.isElementMorphed(tokenIds[i]);
            assert(isMorphed);
        }

        (uint64 lastMorphTime,, uint256 userMorphedTokensCount, uint256 userRate) =
            MorphElementsProxy.morphInfo(addr1, 100);
        uint256 _userRate = baseRate + (baseRateMax * 0) / (km + 0);
        assertEq(_userRate, userRate);
        assertEq(userMorphedTokensCount, tokenIds.length);
        assertEq(lastMorphTime, 1);

        (, uint256 morphedElementsCount) = MorphElementsProxy.morphingPool(100);
        assertEq(morphedElementsCount, tokensCount);
    }

    function test_morphToVolatile_NonExistingMorphPool(uint256 tokensCount) public {
        vm.assume(tokensCount > 0 && tokensCount < 1000);

        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 100, tokensCount);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), tokensCount);

        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(1);

        vm.expectRevert(NonExistingMorphPool.selector);
        MorphElementsProxy.morphToVolatile(101, tokenIds);
    }

    function test_morphToVolatile_NotTokenOwner(uint256 tokensCount) public {
        vm.assume(tokensCount > 0 && tokensCount < 1000);

        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr2, 100, tokensCount);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr2), tokensCount);

        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(1);

        vm.expectRevert(NotTokenOwner.selector);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
    }

    function test_morphToVolatile_NonExistingPoolOrElementId(uint256 tokensCount) public {
        vm.assume(tokensCount > 0 && tokensCount < 1000);

        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 101, tokensCount);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), tokensCount);

        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(1);

        vm.expectRevert(NonExistingPoolOrElementId.selector);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
    }

    function test_morphToVolatile_TokenMorphed(uint256 tokensCount) public {
        vm.assume(tokensCount > 0 && tokensCount < 1000);

        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 100, tokensCount);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), tokensCount);

        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(1);

        MorphElementsProxy.morphToVolatile(100, tokenIds);

        vm.expectRevert(TokenMorphed.selector);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
    }

    // === unMorphing ===

    function test_unMorphElements_MaxRewardCount(uint256 tokensCount, uint64 passedTime) public {
        vm.assume(tokensCount > maxRewardCount && tokensCount < 1000);
        vm.assume(passedTime > periodTime * maxRewardCount);
        /// mint & staking
        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 100, tokensCount);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), tokensCount);

        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        // ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(0);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
        /// ======

        // unmorph
        vm.warp(passedTime);
        uint256 reward = MorphElementsProxy.calculateReward(addr1, 100);
        assertEq(reward, 5);

        uint256[] memory unmorphTokenIds = new uint256[](maxRewardCount);
        for (uint256 i = 0; i < unmorphTokenIds.length; i++) {
            unmorphTokenIds[i] = i + 1;
        }

        MorphElementsProxy.unMorphElements(profileTokenId, 100, unmorphTokenIds);

        (, uint64 lastClaimTime, uint256 userMorphedTokensCount,) = MorphElementsProxy.morphInfo(addr1, 100);
        assertEq(lastClaimTime, passedTime);
        assertEq(userMorphedTokensCount, tokensCount - maxRewardCount);

        uint256 mintedRewardCount = VolatileElementsProxy.balanceOf(addr1, 201);
        assertEq(mintedRewardCount, 5);
    }

    function test_unMorphElements_NoReward_BurnableTokensCountExceeded(uint256 tokensCount, uint64 passedTime) public {
        vm.assume(tokensCount > 0 && tokensCount < 1000);
        vm.assume(passedTime <= periodTime * maxRewardCount);
        vm.assume(passedTime > 0);
        /// mint & staking

        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 100, tokensCount);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), tokensCount);

        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(0);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
        /// ======

        // unMorph
        vm.warp(passedTime);
        uint256 reward = MorphElementsProxy.calculateReward(addr1, 100);
        (,,, uint256 userRate) = MorphElementsProxy.morphInfo(addr1, 100);

        if (reward == 0) {
            vm.expectRevert(NoReward.selector);
            MorphElementsProxy.unMorphElements(profileTokenId, 100, tokenIds);
        } else {
            if (tokenIds.length > (reward * userRate)) {
                vm.expectRevert(BurnableTokensCountExceeded.selector);
                MorphElementsProxy.unMorphElements(profileTokenId, 100, tokenIds);
            } else {
                MorphElementsProxy.unMorphElements(profileTokenId, 100, tokenIds);

                (, uint64 lastClaimTime, uint256 userMorphedTokensCount,) = MorphElementsProxy.morphInfo(addr1, 100);
                assertEq(lastClaimTime, passedTime);
                assertEq(userMorphedTokensCount, 0);

                uint256 mintedRewardCount = VolatileElementsProxy.balanceOf(addr1, 201);
                assertEq(mintedRewardCount, reward);
            }
        }
    }

    function test_unMorphElements_NotTokenOwner() public {
        /// mint & staking
        vm.startPrank(address(MintingContract));

        ElementsProxy.mintElements(addr1, 100, 5);
        assertEq(ElementsProxy.balanceOf(addr1), 5);

        ElementsProxy.mintElements(addr2, 100, 5);
        assertEq(ElementsProxy.balanceOf(addr2), 5);

        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(0);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
        /// ======
        vm.warp(maxRewardCount * tokenIds.length);

        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = i + 6;
        }

        vm.expectRevert(NotTokenOwner.selector);
        MorphElementsProxy.unMorphElements(profileTokenId, 100, tokenIds);
    }

    function test_unMorphElements_NonExistingPoolOrElementId() public {
        /// mint & staking
        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 100, 5);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), 5);

        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        morphMap.push([101, 202]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(0);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
        /// ======
        vm.warp(maxRewardCount * tokenIds.length);

        vm.expectRevert(NonExistingPoolOrElementId.selector);
        MorphElementsProxy.unMorphElements(profileTokenId, 101, tokenIds);
    }

    function test_unMorphElements_TokenNotMorphed() public {
        /// mint & staking
        vm.startPrank(address(MintingContract));
        ElementsProxy.mintElements(addr1, 100, 10);
        vm.stopPrank();

        assertEq(ElementsProxy.balanceOf(addr1), 10);

        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = i + 1;
        }

        // set morph map
        morphMap.push([100, 201]);
        MorphElementsProxy.setMorphMap(morphMap);

        vm.startPrank(addr1);

        ElementsProxy.setApprovalForAll(address(MorphElementsProxy), true);

        // morph tokens
        vm.warp(0);
        MorphElementsProxy.morphToVolatile(100, tokenIds);
        /// ======
        vm.warp(maxRewardCount * tokenIds.length);

        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = i + 6;
        }

        vm.expectRevert(TokenNotMorphed.selector);
        MorphElementsProxy.unMorphElements(profileTokenId, 100, tokenIds);
    }
}
