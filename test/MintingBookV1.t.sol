// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AlchemistSetup} from "test/utils/ContractsSetup.t.sol";

contract MintingBookTest is Test, AlchemistSetup {
    error NotWhitelisted();
    error MintingExpired();
    error WhitelistUsed();

    address public alice;
    address public bob;
    address public george;
    address public aleko;

    bytes32[] internal merkleProof;

    function setUp() public {
        initializeContracts();

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        george = makeAddr("george");
        aleko = makeAddr("aleko");
    }

    function testRevert_acolytMinting_NotWhitelisted() public {
        bytes32[] memory proof = new bytes32[](1);

        vm.expectRevert(NotWhitelisted.selector);
        MintingContract.acolytMinting(proof);
    }

    function testRevert_apprenticeMinting_NotWhitelisted() public {
        bytes32[] memory proof = new bytes32[](1);

        vm.expectRevert(NotWhitelisted.selector);
        MintingContract.apprenticeMinting(proof);
    }

    function testRevert_masterMinting_NotWhitelisted() public {
        bytes32[] memory proof = new bytes32[](1);

        vm.expectRevert(NotWhitelisted.selector);
        MintingContract.masterMinting(proof);

        vm.warp(73 hours);

        vm.expectRevert(MintingExpired.selector);
        MintingContract.masterMinting(proof);
    }

    function test_airdropElements() public {
        address[] memory receivers = new address[](2);
        receivers[0] = address(1);
        receivers[1] = address(2);

        uint24[] memory elementIds = new uint24[](2);
        elementIds[0] = 120;
        elementIds[1] = 125;

        uint256[] memory quantity = new uint256[](2);
        quantity[0] = 25;
        quantity[1] = 25;

        MintingContract.airdropElements(receivers, elementIds, quantity);

        assertEq(ElementsProxy.ownerOf(1), address(1));
        assertEq(ElementsProxy.ownerOf(2), address(2));

        assertEq(ElementsProxy.elementId(1), 120);
        assertEq(ElementsProxy.elementId(2), 125);
    }

    function test_masterMinting() public {
        aleko = 0xFB7897630752cAba5ed3eF4105B023b7Fcbab358;
        vm.startPrank(aleko);

        merkleProof.push(0xbc53abf30c85ff0674f0ec1aa80d3f7d3598bf7d7c02dec7e715cc6b86d9d5a3);
        merkleProof.push(0xbd0c7640c4c4308682192592a0700e194059b2a5f27453f5cfbc4a690d09b92a);

        MintingContract.masterMinting(merkleProof);

        vm.expectRevert(WhitelistUsed.selector);
        MintingContract.masterMinting(merkleProof);
    }
}
