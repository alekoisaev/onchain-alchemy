// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Script, console2} from "forge-std/Script.sol";

// // import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// import {AlchemistProfileV3} from "src/proxies/AlchemistProfileV3.sol";
// // import {ElementsV2} from "src/proxies/ElementsV2.sol";

// contract UpdateProxy is Script {
//     UUPSUpgradeable internal profileProxyAddr;
//     // UUPSUpgradeable internal elementsProxyAddr;

//     address internal ProfileImpl;
//     // address internal ElementsImpl;

//     function setUp() public {}

//     function run() public {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);

//         ProfileImpl = address(new AlchemistProfileV3());
//         // ElementsImpl = address(new ElementsV2());

//         profileProxyAddr = UUPSUpgradeable(vm.envAddress("PROXY_PROFILE"));
//         // elementsProxyAddr = UUPSUpgradeable(vm.envAddress("PROXY_ELEMENTS"));

//         profileProxyAddr.upgradeToAndCall(ProfileImpl, "");
//         // elementsProxyAddr.upgradeToAndCall(ElementsImpl, "");

//         // ElementsV2(address(elementsProxyAddr)).setExternalContracts(
//         //     0x0299B94C981573343CB99cDEB5fb2c2D88EDDFc0,
//         //     0xf8006A2b256Bb265182bD5c2F80474Fca66a0514,
//         //     0x0Aa7d9A40E66c17e9c94719948Ed9049FF4bDCcF
//         // );

//         vm.stopBroadcast();
//     }
// }
