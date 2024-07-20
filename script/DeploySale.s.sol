// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

// import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Elements} from "src/proxies/Elements.sol";
import {MintingBookV1} from "src/proxies/MintingBookV1.sol";

contract DeploySale is Script {
    Elements internal ElementsProxy;
    MintingBookV1 internal mintingBook;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ElementsProxy = Elements(vm.envAddress("PROXY_ELEMENTS"));

        vm.stopBroadcast();
    }
}
