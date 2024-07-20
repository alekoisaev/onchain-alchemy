// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";

import {IElements} from "../interfaces/IElements.sol";

contract MintingBookV1 is Ownable {
    using LibBitmap for LibBitmap.Bitmap;

    error NotWhitelisted();
    error MintingExpired();
    error WhitelistUsed();

    /// Merkle Proofs for Book 1
    bytes32 public AcolytMerkleProof; // Acolyt WL - 4 per wallet
    bytes32 public ApprenticeMerkleProof; // Apprentice WL - 8 per wallet
    bytes32 public MasterMerkleProof; // Master WL - 12 per wallet

    /// 4 Base elements id
    uint24[] public MintElementIds = [100, 101, 102, 103];

    uint256[] public AcolyptQuantity = [1, 1, 1, 1];
    uint256[] public ApprenticeQuantity = [2, 2, 2, 2];
    uint256[] public MasterQuantity = [3, 3, 3, 3];

    /// Book 1 startTime and duration
    uint256 public BookStartTime;
    uint256 public BookDuration = 120 hours;

    IElements public ElementsContract;

    LibBitmap.Bitmap private isWhitelistUsed;

    constructor(address _elementsContract, bytes32 acolyt, bytes32 apprentice, bytes32 master) Ownable(msg.sender) {
        BookStartTime = block.timestamp;
        ElementsContract = IElements(_elementsContract);

        AcolytMerkleProof = acolyt;
        ApprenticeMerkleProof = apprentice;
        MasterMerkleProof = master;
    }

    modifier checkTimer() {
        if (block.timestamp > BookStartTime + BookDuration) revert MintingExpired();
        _;
    }

    /// Book 1 minting

    function acolytMinting(bytes32[] calldata proof) external checkTimer {
        _validateMinter(proof, AcolytMerkleProof);
        ElementsContract.batchMintElements(msg.sender, MintElementIds, AcolyptQuantity);
    }

    function apprenticeMinting(bytes32[] calldata proof) external checkTimer {
        _validateMinter(proof, ApprenticeMerkleProof);
        ElementsContract.batchMintElements(msg.sender, MintElementIds, ApprenticeQuantity);
    }

    function masterMinting(bytes32[] calldata proof) external checkTimer {
        _validateMinter(proof, MasterMerkleProof);
        ElementsContract.batchMintElements(msg.sender, MintElementIds, MasterQuantity);
    }

    /// New Year event airdrop
    function airdropElements(
        address[] calldata _receivers,
        uint24[] calldata _elementIds,
        uint256[] calldata quantity
    ) external onlyOwner {
        if (_receivers.length != _elementIds.length) revert();
        if (_elementIds.length != quantity.length) revert();

        for (uint256 i; i < _receivers.length; i++) {
            ElementsContract.mintElements(_receivers[i], _elementIds[i], quantity[i]);
        }
    }

    function _validateMinter(bytes32[] calldata proof, bytes32 root) internal {
        bytes32 senderLeaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(proof, root, senderLeaf)) revert NotWhitelisted();
        if (isWhitelistUsed.get(uint160(msg.sender))) revert WhitelistUsed();
        isWhitelistUsed.set(uint160(msg.sender));
    }

    function getIsWhitelistUsed(address sender) public view returns (bool) {
        return isWhitelistUsed.get(uint160(sender));
    }
}
