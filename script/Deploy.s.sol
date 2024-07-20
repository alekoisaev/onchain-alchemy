// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Elements} from "src/proxies/Elements.sol";
import {VolatileElements} from "src/proxies/VolatileElements.sol";
import {Merging} from "src/proxies/Merging.sol";
import {MorphElements} from "src/proxies/MorphElements.sol";
import {AlchemistProfile} from "src/proxies/AlchemistProfile.sol";
import {Achievements} from "src/proxies/Achievements.sol";
import {MintingBookV1} from "src/proxies/MintingBookV1.sol";

contract DeployScript is Script {
    address internal ElementsImpl;
    address internal VolatileElementsImpl;
    address internal MergingImpl;
    address internal MorphElementsImpl;
    address internal AlchemistProfileImpl;
    address internal AchievementsImpl;

    Elements internal ElementsProxy;
    VolatileElements internal VolatileElementsProxy;
    Merging internal MergingProxy;
    MorphElements internal MorphElementsProxy;
    AlchemistProfile internal AlchemistProfileProxy;
    Achievements internal AchievementsProxy;

    MintingBookV1 internal MintingContract;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        initializeContracts();

        addLvlingData();

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
        MorphElementsImpl = address(new MorphElements());
        AlchemistProfileImpl = address(new AlchemistProfile());
        AchievementsImpl = address(new Achievements());
    }

    function deployProxies() internal {
        ElementsProxy = Elements(address(new ERC1967Proxy(ElementsImpl, abi.encodeWithSignature("initialize()"))));
        VolatileElementsProxy =
            VolatileElements(address(new ERC1967Proxy(VolatileElementsImpl, abi.encodeWithSignature("initialize()"))));
        MergingProxy = Merging(address(new ERC1967Proxy(MergingImpl, abi.encodeWithSignature("initialize()"))));
        MorphElementsProxy =
            MorphElements(address(new ERC1967Proxy(MorphElementsImpl, abi.encodeWithSignature("initialize()"))));
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

        ElementsProxy.setExternalContracts(
            address(MorphElementsProxy), address(MergingProxy), address(AlchemistProfileProxy)
        );
        MorphElementsProxy.setExternalContracts(
            address(ElementsProxy), address(VolatileElementsProxy), address(AlchemistProfileProxy)
        );
        MergingProxy.setExternalContracts(
            address(ElementsProxy), address(VolatileElementsProxy), address(AlchemistProfileProxy)
        );
        AlchemistProfileProxy.setExternalContracts(
            address(ElementsProxy), address(MergingProxy), address(MorphElementsProxy), address(AchievementsProxy)
        );
    }

    function deployMinter() internal {
        MintingContract = new MintingBookV1(
            address(ElementsProxy),
            0xf4981ed5c68744a695a7badd6a79aadefdd31b34860d2b096ec184cd45dfdb1a,
            0xc62ec37896350eaf5cb61dcdc3631726dd9a4deac7ab89985ccffcbcc560f9bc,
            0x49bdbb504db8a929bf64be39039b5bf7ac2ff4ed996a682b3420ef8b50da273b
        );

        ElementsProxy.setMinter(address(0), address(MintingContract), 1);
    }

    function addLvlingData() internal {
        uint256[] memory lvls = new uint256[](10);
        uint256[] memory xps = new uint256[](10);

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

        AlchemistProfileProxy.setLvlData(lvls, xps);
    }
}
