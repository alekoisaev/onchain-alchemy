// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Elements} from "src/proxies/Elements.sol";
import {VolatileElements} from "src/proxies/VolatileElements.sol";
import {Merging} from "src/proxies/Merging.sol";
// import {MorphElements} from "src/proxies/MorphElements.sol";
import {AlchemistProfile} from "src/proxies/AlchemistProfile.sol";
import {Achievements} from "src/proxies/Achievements.sol";
import {MintingBookV1} from "src/proxies/MintingBookV1.sol";

contract DeployScript is Script {
    address internal ElementsImpl;
    address internal VolatileElementsImpl;
    address internal MergingImpl;
    // address internal MorphElementsImpl;
    address internal AlchemistProfileImpl;
    address internal AchievementsImpl;

    Elements internal ElementsProxy;
    VolatileElements internal VolatileElementsProxy;
    Merging internal MergingProxy;
    // MorphElements internal MorphElementsProxy;
    AlchemistProfile internal AlchemistProfileProxy;
    Achievements internal AchievementsProxy;

    MintingBookV1 internal MintingContract;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        initializeContracts();

        addLvlingData();
        addTypeIds();
        addElementLimits();

        deployMinter();

        console2.logAddress(address(ElementsProxy));
        console2.logAddress(address(MergingProxy));
        console2.logAddress(address(AlchemistProfileProxy));

        vm.stopBroadcast();
    }

    /// set up ...

    function deployImplements() internal {
        ElementsImpl = address(new Elements());
        VolatileElementsImpl = address(new VolatileElements());
        MergingImpl = address(new Merging());
        // MorphElementsImpl = address(new MorphElements());
        AlchemistProfileImpl = address(new AlchemistProfile());
        AchievementsImpl = address(new Achievements());
    }

    function deployProxies() internal {
        ElementsProxy = Elements(address(new ERC1967Proxy(ElementsImpl, abi.encodeWithSignature("initialize()"))));
        VolatileElementsProxy =
            VolatileElements(address(new ERC1967Proxy(VolatileElementsImpl, abi.encodeWithSignature("initialize()"))));
        MergingProxy = Merging(address(new ERC1967Proxy(MergingImpl, abi.encodeWithSignature("initialize()"))));
        // MorphElementsProxy = MorphElements(
        //     address(new ERC1967Proxy(MorphElementsImpl, abi.encodeWithSignature("initialize()")))
        // );
        AlchemistProfileProxy =
            AlchemistProfile(address(new ERC1967Proxy(AlchemistProfileImpl, abi.encodeWithSignature("initialize()"))));
        AchievementsProxy = Achievements(
            address(
                new ERC1967Proxy(
                    AchievementsImpl,
                    abi.encodeWithSignature("initialize(address,address)", AlchemistProfileProxy, ElementsProxy)
                )
            )
        );
    }

    function initializeContracts() internal {
        deployImplements();
        deployProxies();

        ElementsProxy.setExternalContracts(address(0), address(MergingProxy), address(AlchemistProfileProxy));
        // MorphElementsProxy.setExternalContracts(
        //     address(ElementsProxy),
        //     address(VolatileElementsProxy),
        //     address(AlchemistProfileProxy)
        // );
        MergingProxy.setExternalContracts(
            address(ElementsProxy), address(VolatileElementsProxy), address(AlchemistProfileProxy)
        );
        AlchemistProfileProxy.setExternalContracts(
            address(ElementsProxy), address(MergingProxy), address(0), address(AchievementsProxy)
        );

        ElementsProxy.setAnimationURI("https://gen.onchainalchemy.io/");
    }

    function deployMinter() internal {
        MintingContract = new MintingBookV1(
            address(ElementsProxy),
            0xa318113038984563246692552f72eccd92421e392a291124d9645f7a4015d443,
            0x3d4ad74b35265f96a9f003cb583a684687b20b3e57519cbad3a2e4c408300fee,
            0xcf9af243611f344f91a07e7e24a8143a8a58bd43582a5668e0b5340ed44dd2cc
        );

        ElementsProxy.setMinter(address(0), address(MintingContract), 1);
    }

    function addLvlingData() internal {
        uint256[] memory lvls = new uint256[](11);
        uint256[] memory xps = new uint256[](11);

        lvls[0] = 1;
        xps[0] = 0;

        lvls[1] = 2;
        xps[1] = 230;

        lvls[2] = 3;
        xps[2] = 250;

        lvls[3] = 4;
        xps[3] = 275;

        lvls[4] = 5;
        xps[4] = 300;

        lvls[5] = 6;
        xps[5] = 325;

        lvls[6] = 7;
        xps[6] = 355;

        lvls[7] = 8;
        xps[7] = 385;

        lvls[8] = 9;
        xps[8] = 420;

        lvls[9] = 10;
        xps[9] = 455;

        lvls[10] = 11;
        xps[10] = 495;

        AlchemistProfileProxy.setLvlData(lvls, xps);
    }

    function addTypeIds() internal {
        uint24[] memory elementIds = new uint24[](58);
        uint24[] memory typeIds = new uint24[](58);
        uint256[] memory masteryPoints = new uint256[](58);
        uint256[] memory masteryBonuses = new uint256[](58);
        string[] memory elementNames = new string[](58);

        elementIds[0] = 100;
        typeIds[0] = 1;
        masteryPoints[0] = 0;
        masteryBonuses[0] = 0;
        elementNames[0] = "Fire";

        elementIds[1] = 101;
        typeIds[1] = 2;
        masteryPoints[1] = 0;
        masteryBonuses[1] = 0;
        elementNames[1] = "Water";

        elementIds[2] = 102;
        typeIds[2] = 3;
        masteryPoints[2] = 0;
        masteryBonuses[2] = 0;
        elementNames[2] = "Earth";

        elementIds[3] = 103;
        typeIds[3] = 4;
        masteryPoints[3] = 0;
        masteryBonuses[3] = 0;
        elementNames[3] = "Air";

        elementIds[4] = 104;
        typeIds[4] = 3;
        masteryPoints[4] = 1;
        masteryBonuses[4] = 1;
        elementNames[4] = "Dust";

        elementIds[5] = 105;
        typeIds[5] = 2;
        masteryPoints[5] = 1;
        masteryBonuses[5] = 1;
        elementNames[5] = "Lake";

        elementIds[6] = 106;
        typeIds[6] = 2;
        masteryPoints[6] = 1;
        masteryBonuses[6] = 1;
        elementNames[6] = "Steam";

        elementIds[7] = 107;
        typeIds[7] = 4;
        masteryPoints[7] = 1;
        masteryBonuses[7] = 1;
        elementNames[7] = "Wind";

        elementIds[8] = 108;
        typeIds[8] = 3;
        masteryPoints[8] = 1;
        masteryBonuses[8] = 1;
        elementNames[8] = "Hill";

        elementIds[9] = 109;
        typeIds[9] = 5;
        masteryPoints[9] = 1;
        masteryBonuses[9] = 1;
        elementNames[9] = "Mistral Orb";

        elementIds[10] = 110;
        typeIds[10] = 5;
        masteryPoints[10] = 1;
        masteryBonuses[10] = 1;
        elementNames[10] = "Emberstone";

        elementIds[11] = 111;
        typeIds[11] = 1;
        masteryPoints[11] = 1;
        masteryBonuses[11] = 1;
        elementNames[11] = "Infernal Core";

        elementIds[12] = 112;
        typeIds[12] = 1;
        masteryPoints[12] = 1;
        masteryBonuses[12] = 1;
        elementNames[12] = "Blazing Zephyr";

        elementIds[13] = 113;
        typeIds[13] = 5;
        masteryPoints[13] = 1;
        masteryBonuses[13] = 1;
        elementNames[13] = "Aqua-Terra";

        elementIds[14] = 114;
        typeIds[14] = 2;
        masteryPoints[14] = 1;
        masteryBonuses[14] = 1;
        elementNames[14] = "Stream";

        elementIds[15] = 115;
        typeIds[15] = 3;
        masteryPoints[15] = 1;
        masteryBonuses[15] = 1;
        elementNames[15] = "Mountain";

        elementIds[16] = 116;
        typeIds[16] = 1;
        masteryPoints[16] = 1;
        masteryBonuses[16] = 1;
        elementNames[16] = "Magma";

        elementIds[17] = 117;
        typeIds[17] = 1;
        masteryPoints[17] = 1;
        masteryBonuses[17] = 31;
        elementNames[17] = "Zephyr's Flame Gem";

        elementIds[18] = 118;
        typeIds[18] = 4;
        masteryPoints[18] = 1;
        masteryBonuses[18] = 1;
        elementNames[18] = "Cloud";

        elementIds[19] = 119;
        typeIds[19] = 2;
        masteryPoints[19] = 1;
        masteryBonuses[19] = 1;
        elementNames[19] = "Sea";

        elementIds[20] = 120;
        typeIds[20] = 2;
        masteryPoints[20] = 1;
        masteryBonuses[20] = 1;
        elementNames[20] = "River";

        elementIds[21] = 121;
        typeIds[21] = 2;
        masteryPoints[21] = 1;
        masteryBonuses[21] = 1;
        elementNames[21] = "Rain";

        elementIds[22] = 122;
        typeIds[22] = 4;
        masteryPoints[22] = 1;
        masteryBonuses[22] = 1;
        elementNames[22] = "Fog";

        elementIds[23] = 123;
        typeIds[23] = 1;
        masteryPoints[23] = 1;
        masteryBonuses[23] = 1;
        elementNames[23] = "Volcano";

        elementIds[24] = 124;
        typeIds[24] = 5;
        masteryPoints[24] = 1;
        masteryBonuses[24] = 138;
        elementNames[24] = "Mistflame Shard";

        elementIds[25] = 125;
        typeIds[25] = 4;
        masteryPoints[25] = 2;
        masteryBonuses[25] = 2;
        elementNames[25] = "Mistral Essence";

        elementIds[26] = 126;
        typeIds[26] = 4;
        masteryPoints[26] = 4;
        masteryBonuses[26] = 63;
        elementNames[26] = "Phantom Veil Gem";

        elementIds[27] = 127;
        typeIds[27] = 1;
        masteryPoints[27] = 1;
        masteryBonuses[27] = 1;
        elementNames[27] = "Volcanic Ash";

        elementIds[28] = 128;
        typeIds[28] = 1;
        masteryPoints[28] = 1;
        masteryBonuses[28] = 1;
        elementNames[28] = "Lava";

        elementIds[29] = 129;
        typeIds[29] = 4;
        masteryPoints[29] = 1;
        masteryBonuses[29] = 1;
        elementNames[29] = "Storm";

        elementIds[30] = 130;
        typeIds[30] = 5;
        masteryPoints[30] = 1;
        masteryBonuses[30] = 251;
        elementNames[30] = "Ashen Steam Orb";

        elementIds[31] = 131;
        typeIds[31] = 3;
        masteryPoints[31] = 1;
        masteryBonuses[31] = 1;
        elementNames[31] = "Stone";

        elementIds[32] = 132;
        typeIds[32] = 1;
        masteryPoints[32] = 1;
        masteryBonuses[32] = 1;
        elementNames[32] = "Fire Storm";

        elementIds[33] = 133;
        typeIds[33] = 4;
        masteryPoints[33] = 1;
        masteryBonuses[33] = 1;
        elementNames[33] = "Dust Storm";

        elementIds[34] = 134;
        typeIds[34] = 4;
        masteryPoints[34] = 1;
        masteryBonuses[34] = 1;
        elementNames[34] = "Volcanic Gas";

        elementIds[35] = 135;
        typeIds[35] = 2;
        masteryPoints[35] = 1;
        masteryBonuses[35] = 59;
        elementNames[35] = "Rivermist Stone";

        elementIds[36] = 136;
        typeIds[36] = 4;
        masteryPoints[36] = 1;
        masteryBonuses[36] = 1;
        elementNames[36] = "Carbon Dioxide";

        elementIds[37] = 137;
        typeIds[37] = 3;
        masteryPoints[37] = 1;
        masteryBonuses[37] = 1;
        elementNames[37] = "Brimstone";

        elementIds[38] = 138;
        typeIds[38] = 2;
        masteryPoints[38] = 1;
        masteryBonuses[38] = 1;
        elementNames[38] = "Ocean";

        elementIds[39] = 139;
        typeIds[39] = 3;
        masteryPoints[39] = 1;
        masteryBonuses[39] = 1;
        elementNames[39] = "Pebbles";

        elementIds[40] = 140;
        typeIds[40] = 1;
        masteryPoints[40] = 2;
        masteryBonuses[40] = 2;
        elementNames[40] = "Sulfur Heart Stone";

        elementIds[41] = 141;
        typeIds[41] = 1;
        masteryPoints[41] = 7;
        masteryBonuses[41] = 120;
        elementNames[41] = "Hellfire Shard";

        elementIds[42] = 142;
        typeIds[42] = 2;
        masteryPoints[42] = 1;
        masteryBonuses[42] = 1;
        elementNames[42] = "Acid Rain";

        elementIds[43] = 143;
        typeIds[43] = 5;
        masteryPoints[43] = 2;
        masteryBonuses[43] = 2;
        elementNames[43] = "Volcanic Heartstone";

        elementIds[44] = 144;
        typeIds[44] = 5;
        masteryPoints[44] = 14;
        masteryBonuses[44] = 129;
        elementNames[44] = "Pyroclasm Sphere";

        elementIds[45] = 145;
        typeIds[45] = 5;
        masteryPoints[45] = 1;
        masteryBonuses[45] = 429;
        elementNames[45] = "Titan's Heartstone";

        elementIds[46] = 146;
        typeIds[46] = 3;
        masteryPoints[46] = 1;
        masteryBonuses[46] = 1;
        elementNames[46] = "Sand";

        elementIds[47] = 147;
        typeIds[47] = 5;
        masteryPoints[47] = 1;
        masteryBonuses[47] = 1;
        elementNames[47] = "Geothermal Essence";

        elementIds[48] = 148;
        typeIds[48] = 3;
        masteryPoints[48] = 1;
        masteryBonuses[48] = 1;
        elementNames[48] = "Silt";

        elementIds[49] = 149;
        typeIds[49] = 5;
        masteryPoints[49] = 1;
        masteryBonuses[49] = 112;
        elementNames[49] = "Cyclone Blaze Orb";

        elementIds[50] = 150;
        typeIds[50] = 5;
        masteryPoints[50] = 2;
        masteryBonuses[50] = 139;
        elementNames[50] = "Inferno Breath Crystal";

        elementIds[51] = 151;
        typeIds[51] = 3;
        masteryPoints[51] = 2;
        masteryBonuses[51] = 2;
        elementNames[51] = "Sandstorm";

        elementIds[52] = 152;
        typeIds[52] = 5;
        masteryPoints[52] = 2;
        masteryBonuses[52] = 179;
        elementNames[52] = "Ashen Fury Stone";

        elementIds[53] = 153;
        typeIds[53] = 5;
        masteryPoints[53] = 2;
        masteryBonuses[53] = 252;
        elementNames[53] = "Dune Tide Crystal";

        elementIds[54] = 154;
        typeIds[54] = 3;
        masteryPoints[54] = 2;
        masteryBonuses[54] = 2;
        elementNames[54] = "Clay";

        elementIds[55] = 155;
        typeIds[55] = 3;
        masteryPoints[55] = 9;
        masteryBonuses[55] = 11;
        elementNames[55] = "Gold";

        elementIds[56] = 156;
        typeIds[56] = 5;
        masteryPoints[56] = 52;
        masteryBonuses[56] = 627;
        elementNames[56] = "Alluvial Crystal";

        elementIds[57] = 157;
        typeIds[57] = 5;
        masteryPoints[57] = 2;
        masteryBonuses[57] = 430;
        elementNames[57] = "Desert Sculptor's Orb";

        ElementsProxy.setElementURIs(elementIds, typeIds, masteryPoints, masteryBonuses, elementNames);
    }

    function addElementLimits() internal {
        uint256[2][] memory elementLimits = new uint256[2][](14);

        elementLimits[0] = [uint256(117), uint256(100)];
        elementLimits[1] = [uint256(124), uint256(20)];
        elementLimits[2] = [uint256(126), uint256(50)];
        elementLimits[3] = [uint256(130), uint256(10)];
        elementLimits[4] = [uint256(135), uint256(50)];
        elementLimits[5] = [uint256(141), uint256(25)];
        elementLimits[6] = [uint256(144), uint256(25)];
        elementLimits[7] = [uint256(145), uint256(6)];
        elementLimits[8] = [uint256(149), uint256(25)];
        elementLimits[9] = [uint256(150), uint256(20)];
        elementLimits[10] = [uint256(152), uint256(15)];
        elementLimits[11] = [uint256(153), uint256(10)];
        elementLimits[12] = [uint256(156), uint256(3)];
        elementLimits[13] = [uint256(157), uint256(5)];

        ElementsProxy.setElementLimits(elementLimits);
    }
}
