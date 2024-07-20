// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {AlchemistSetup} from "test/utils/ContractsSetup.t.sol";

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Achievements} from "src/proxies/Achievements.sol";

contract AchievementsTest is Test, AlchemistSetup, ERC1155Holder {
    using stdStorage for StdStorage;

    struct AchievStruct {
        uint256 xp;
        bool isMajor;
    }

    function setUp() public {
        initializeContracts();

        addLvlConds();
        addMergingConds();
    }

    function test_claimLvlAchievs() public {
        uint256 profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        stdstore.target(address(AlchemistProfileProxy)).sig("profileData(uint256)").with_key(profileTokenId).depth(2)
            .checked_write(1500);

        AchievementsProxy.claimLvlAchievs(profileTokenId);

        assertEq(AchievementsProxy.balanceOf(address(this), 5), 1);
    }

    function test_claimMergingAchievs() public {
        uint256 profileTokenId = AlchemistProfileProxy.createProfile("0xAleko", "photolink");

        stdstore.target(address(AlchemistProfileProxy)).sig("profileData(uint256)").with_key(profileTokenId).depth(4)
            .checked_write(30);

        AchievementsProxy.claimMergingAchievs(profileTokenId);

        assertEq(AchievementsProxy.balanceOf(address(this), 101), 1);
        assertEq(AchievementsProxy.balanceOf(address(this), 102), 1);
        assertEq(AchievementsProxy.balanceOf(address(this), 103), 1);
        assertEq(AchievementsProxy.balanceOf(address(this), 104), 1);
        assertEq(AchievementsProxy.balanceOf(address(this), 105), 1);
        assertEq(AchievementsProxy.balanceOf(address(this), 106), 1);
    }

    function addLvlConds() internal {
        Achievements.AchievStruct[] memory levelingAchievs = new Achievements.AchievStruct[](10);

        levelingAchievs[0] = Achievements.AchievStruct(5, 1055, false);
        levelingAchievs[1] = Achievements.AchievStruct(10, 2995, true);
        levelingAchievs[2] = Achievements.AchievStruct(15, 5900, false);
        levelingAchievs[3] = Achievements.AchievStruct(20, 10060, false);
        levelingAchievs[4] = Achievements.AchievStruct(25, 15695, true);
        levelingAchievs[5] = Achievements.AchievStruct(30, 22865, false);
        levelingAchievs[6] = Achievements.AchievStruct(35, 31480, false);
        levelingAchievs[7] = Achievements.AchievStruct(40, 41290, false);
        levelingAchievs[8] = Achievements.AchievStruct(45, 52005, false);
        levelingAchievs[9] = Achievements.AchievStruct(50, 63350, true);

        AchievementsProxy.addAchievsCond("lvling", levelingAchievs);
    }

    function addMergingConds() internal {
        Achievements.AchievStruct[] memory mergingAchievs = new Achievements.AchievStruct[](14);

        mergingAchievs[0] = Achievements.AchievStruct(101, 5, false);
        mergingAchievs[1] = Achievements.AchievStruct(102, 10, true);
        mergingAchievs[2] = Achievements.AchievStruct(103, 15, false);
        mergingAchievs[3] = Achievements.AchievStruct(104, 20, false);
        mergingAchievs[4] = Achievements.AchievStruct(105, 25, true);
        mergingAchievs[5] = Achievements.AchievStruct(106, 30, false);
        mergingAchievs[6] = Achievements.AchievStruct(107, 40, false);
        mergingAchievs[7] = Achievements.AchievStruct(108, 50, true);
        mergingAchievs[8] = Achievements.AchievStruct(109, 60, false);
        mergingAchievs[9] = Achievements.AchievStruct(110, 70, false);
        mergingAchievs[10] = Achievements.AchievStruct(111, 80, false);
        mergingAchievs[11] = Achievements.AchievStruct(112, 90, false);
        mergingAchievs[12] = Achievements.AchievStruct(113, 100, true);
        mergingAchievs[13] = Achievements.AchievStruct(114, 125, false);

        AchievementsProxy.addAchievsCond("merging", mergingAchievs);
    }

    // function addStakingConds() internal {
    //     Achievements.AchievStruct[] memory stakingAchievs = new Achievements.AchievStruct[](14);

    //     // stakingAchievs[0] = Achievements.AchievStruct(201, );
    //     stakingAchievs[1] = Achievements.AchievStruct();
    //     stakingAchievs[2] = Achievements.AchievStruct();
    //     stakingAchievs[3] = Achievements.AchievStruct();
    //     stakingAchievs[4] = Achievements.AchievStruct();
    //     stakingAchievs[5] = Achievements.AchievStruct();
    //     stakingAchievs[6] = Achievements.AchievStruct();
    //     stakingAchievs[7] = Achievements.AchievStruct();
    //     stakingAchievs[8] = Achievements.AchievStruct();
    //     stakingAchievs[9] = Achievements.AchievStruct();
    //     stakingAchievs[10] = Achievements.AchievStruct();
    //     stakingAchievs[11] = Achievements.AchievStruct();
    //     stakingAchievs[12] = Achievements.AchievStruct();
    //     stakingAchievs[13] = Achievements.AchievStruct();
    //     stakingAchievs[14] = Achievements.AchievStruct();
    // }
}
