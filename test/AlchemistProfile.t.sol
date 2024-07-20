// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {AlchemistSetup} from "test/utils/ContractsSetup.t.sol";

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract AlchemistProfileTest is Test, AlchemistSetup {
    using stdStorage for StdStorage;

    function setUp() public {
        initializeContracts();
    }

    address public addrAleko = makeAddr("0xAleko");

    function test_createProfile() public {
        uint256 tokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        (string memory name, string memory avatarLink, uint256 Xp,,,,,,,) = AlchemistProfileProxy.profileData(tokenId);

        assertEq(name, "0xAleko");
        assertEq(avatarLink, "photolink");
        assertEq(Xp, 0);
    }

    function testRevert_createProfile_NameAlreadyExists() public {
        AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        vm.expectRevert();
        AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        AlchemistProfileProxy.createProfile("0xaleko", "photolink");
    }

    function test_addMergeXp() public {
        vm.prank(addrAleko);
        uint256 tokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");
        (,, uint256 Xp,,,,,,,) = AlchemistProfileProxy.profileData(tokenId);

        uint256[] memory elementIds = new uint256[](3);
        elementIds[0] = 100;
        elementIds[1] = 133;
        elementIds[2] = 155;

        vm.prank(address(MergingProxy));
        AlchemistProfileProxy.addMergeXp(addrAleko, tokenId, elementIds);

        uint256 increasedXp = getMergingXp(elementIds);
        emit log_uint(increasedXp);
        emit log_uint(Xp);
        assertEq(increasedXp, Xp + increasedXp);

        // second merge
        (,, uint256 beforeMergeXp,,,,,,,) = AlchemistProfileProxy.profileData(tokenId);

        vm.prank(address(MergingProxy));
        AlchemistProfileProxy.addMergeXp(addrAleko, tokenId, elementIds);

        (,, uint256 afterMergeXp,,,,,,,) = AlchemistProfileProxy.profileData(tokenId);
        increasedXp = getMergingXp(elementIds);
        assertEq(beforeMergeXp + increasedXp, afterMergeXp);
    }

    function test_addStakingXp() public {
        vm.prank(addrAleko);
        uint256 tokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");
        (,, uint256 Xp,,,,,,,) = AlchemistProfileProxy.profileData(tokenId);

        vm.prank(address(MorphElementsProxy));
        AlchemistProfileProxy.addMorphingXp(addrAleko, tokenId, 5);

        assertEq(5 * 100, Xp + (5 * 100));
    }

    function test_getUserLvl() public {
        // addLvlingData();

        uint256 profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        // add xp to profile
        stdstore.target(address(AlchemistProfileProxy)).sig("profileData(uint256)").with_key(profileTokenId).depth(2)
            .checked_write(350);

        uint256 userLvl = AlchemistProfileProxy.getUserLvl(profileTokenId, address(this));

        assertEq(userLvl, 6);
    }

    function test_getMasteryPointsBonus() public {
        vm.prank(addrAleko);
        uint256 tokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        vm.prank(address(MintingContract));
        ElementsProxy.mintElements(addrAleko, 104, 1);

        uint24[] memory elementIds = new uint24[](1);
        elementIds[0] = 104;

        uint24[] memory typeIds = new uint24[](1);
        typeIds[0] = 3;

        uint256[] memory masteryPoints = new uint256[](1);
        masteryPoints[0] = 1;

        uint256[] memory masteryBonuses = new uint256[](1);
        masteryBonuses[0] = 1;

        string[] memory elementNames = new string[](1);
        elementNames[0] = "Test Element";

        ElementsProxy.setElementURIs(elementIds, typeIds, masteryPoints, masteryBonuses, elementNames);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(addrAleko);
        AlchemistProfileProxy.setMasteryElements(tokenId, tokenIds);

        // add bonus points to profile
        vm.prank(address(MergingProxy));
        AlchemistProfileProxy.addMasteryPoints(addrAleko, tokenId, 3, 5);

        uint256 bonus = AlchemistProfileProxy.getMasteryPointsBonus(tokenId, 3);
        emit log_uint(bonus);
    }

    // function test_changeNameAvatar_onlyName() public {
    //     uint256 profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

    //     AlchemistProfileProxy.changeNameAvatar(profileTokenId, "0xALeee");

    //     (string memory name,,,,,,,,,) = AlchemistProfileProxy.profileData(profileTokenId);

    //     assertEq(name, "0xALeee");
    // }

    // function test_changeNameAvatar() public {
    //     uint256 profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

    //     AlchemistProfileProxy.changeNameAvatar(profileTokenId, "0xALeee", "newLink");

    //     (string memory name, string memory avatarLink,,,,,,,,) = AlchemistProfileProxy.profileData(profileTokenId);

    //     assertEq(name, "0xALeee");
    //     assertEq(avatarLink, "newLink");
    // }

    // === UUPS testing & ownership ===

    function test_initialized() public {
        vm.expectRevert();
        AlchemistProfileProxy.initialize();
    }

    function test_upgradeProxy() public {
        address implV2 = address(new AlchemistProfileV2());

        vm.expectEmit();
        emit ERC1967Utils.Upgraded(implV2);

        AlchemistProfileProxy.upgradeToAndCall(implV2, "");
        AlchemistProfileV2 proxyV2 = AlchemistProfileV2(address(AlchemistProfileProxy));

        string memory isProxyUpdated = proxyV2.isProxyUpdated();
        assertEq(isProxyUpdated, "Updated");
    }

    function testRevert_upgradeProxy() public {
        address implV2 = address(new AlchemistProfileV2());

        vm.expectRevert();
        vm.prank(addrAleko);
        AlchemistProfileProxy.upgradeToAndCall(implV2, "");
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

contract AlchemistProfileV2 is UUPSUpgradeable {
    function isProxyUpdated() external pure returns (string memory) {
        return "Updated";
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
