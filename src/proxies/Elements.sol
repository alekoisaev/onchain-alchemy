// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IMorphElements} from "../interfaces/IMorph.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {Base64} from "solady/src/utils/Base64.sol";

contract Elements is ERC721AUpgradeable, UUPSUpgradeable, AccessControlUpgradeable {
    using LibBitmap for LibBitmap.Bitmap;
    using LibString for uint256;

    // === ERRORS ===
    error Unauthorized(address sender);
    error IncorrectElementId();
    error NonEqualArrays();
    error TokenMorphed();
    error TokenMasteryLocked();
    error NotAuthorized();
    error ElementLimitReached();
    error NotWhitelisted();

    // === STORAGE ===
    struct RareElementLimits {
        uint256 limit;
        bool isLimitedElement;
    }

    struct ElementURIStruct {
        // ...
        uint24 elementTypeId;
        uint256 masteryPoints;
        uint256 masteryBonus;
        string elementName;
    }

    LibBitmap.Bitmap private userApprovePass;
    LibBitmap.Bitmap private isElementMasteryLocked;

    mapping(uint24 => ElementURIStruct) public elementURI;
    mapping(uint24 => RareElementLimits) public elementLimits;
    mapping(uint256 => bytes32) public tokenIdToHash;

    address public MergeContract;
    address public MorphContract;

    bytes32 public constant MERGE_CONTRACT_ROLE = keccak256("MERGE");
    bytes32 public constant MORPH_CONTRACT_ROLE = keccak256("MORPH");
    bytes32 public constant PROFILE_CONTRACT_ROLE = keccak256("PROFILE");
    bytes32 public constant MINTER_CONTRACT_ROLE = keccak256("SALE");

    uint256 public bookNumber;

    string public animationURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer initializerERC721A {
        __ERC721A_init("OnChain Alchemy (BETA)", "ALCH");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // === MAIN ===
    modifier onlyAdmin(address _sender) {
        if (
            !(
                hasRole(MERGE_CONTRACT_ROLE, _sender) || hasRole(MORPH_CONTRACT_ROLE, _sender)
                    || hasRole(MINTER_CONTRACT_ROLE, _sender)
            )
        ) revert Unauthorized(_sender);
        _;
    }

    function batchMintElements(
        address receiver,
        uint24[] calldata _elementIds,
        uint256[] calldata counts
    ) external onlyRole(MINTER_CONTRACT_ROLE) {
        for (uint256 i; i < _elementIds.length; ++i) {
            _mintElements(receiver, _elementIds[i], counts[i]);
        }
    }

    function coreBurnElements(uint256[] calldata tokenIds) external onlyAdmin(msg.sender) {
        for (uint256 i; i < tokenIds.length; ++i) {
            if (!userApprovePass.get(uint160(ownerOf(tokenIds[i])))) {
                _burn(tokenIds[i]);
            } else {
                _burn(tokenIds[i], true);
            }
        }
    }

    function burnElements(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ++i) {
            _burn(tokenIds[i], true);
        }
    }

    function mintElements(address to, uint24 _elementId, uint256 count) public onlyAdmin(msg.sender) {
        if (_elementId < 100 || _elementId > 999) revert IncorrectElementId();

        RareElementLimits storage _elementLimits = elementLimits[_elementId];
        if (_elementLimits.isLimitedElement) {
            if (_elementLimits.limit < count) revert ElementLimitReached();
            _elementLimits.limit -= count;
        }

        _mintElements(to, _elementId, count);
    }

    function _mintElements(address to, uint24 _elementId, uint256 count) internal {
        uint256 _tokenId = _nextTokenId();
        for (uint256 i = _tokenId; i < _tokenId + count; i++) {
            bytes32 tokenHash = keccak256(abi.encodePacked(block.number, blockhash(block.number - 1), to, i));
            tokenIdToHash[i] = tokenHash;
        }

        _mint(to, count);
        // set elementId as extraData of erc721a
        _setExtraDataAt(_nextTokenId() - count, _elementId);
    }

    function setUserApprovePass() external {
        uint256 sender = uint160(msg.sender);
        bool state = userApprovePass.get(sender);

        if (!state) userApprovePass.set(sender);
        else userApprovePass.unset(sender);
    }

    function setMasteryActiveElement(uint256 tokenId, bool lock) external onlyRole(PROFILE_CONTRACT_ROLE) {
        if (lock) isElementMasteryLocked.set(tokenId);
        else isElementMasteryLocked.unset(tokenId);
    }

    // === metadata ===
    function getElementLimits(uint24 _elementId) public view returns (bool, uint256) {
        RareElementLimits storage _elementLimits = elementLimits[_elementId];
        if (_elementLimits.isLimitedElement) {
            return (true, _elementLimits.limit);
        }
        return (false, 0);
    }

    function isApprovedPass(address sender) public view returns (bool) {
        return userApprovePass.get(uint160(sender));
    }

    function elementId(uint256 tokenId) public view returns (uint256) {
        return _ownershipOf(tokenId).extraData;
    }

    function elementTypeId(uint256 tokenId) public view returns (uint24) {
        return elementURI[uint24(elementId(tokenId))].elementTypeId;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function userTotalMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // === admin ===
    function setAnimationURI(string calldata newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        animationURI = newURI;
    }

    function setMinter(
        address oldMinter,
        address newMinter,
        uint256 _bookNumber
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_CONTRACT_ROLE, oldMinter);
        grantRole(MINTER_CONTRACT_ROLE, newMinter);
        bookNumber = _bookNumber;
    }

    function setExternalContracts(
        address _morphContract,
        address _mergeContract,
        address _profileContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MorphContract = _morphContract;

        // grantRole(MORPH_CONTRACT_ROLE, _morphContract);
        grantRole(MERGE_CONTRACT_ROLE, _mergeContract);
        grantRole(PROFILE_CONTRACT_ROLE, _profileContract);
    }

    function setElementLimits(uint256[2][] calldata limits) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < limits.length; i++) {
            elementLimits[uint24(limits[i][0])] = RareElementLimits(limits[i][1], true);
        }
    }

    function setElementURIs(
        uint24[] calldata _elementIds,
        uint24[] calldata _typeIds,
        uint256[] calldata _masteryPoints,
        uint256[] calldata _masteryBonuses,
        string[] calldata _elementNames
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 elementsCount = _elementIds.length;
        if (_typeIds.length != elementsCount) revert NonEqualArrays();
        if (_masteryPoints.length != elementsCount) revert NonEqualArrays();
        if (_masteryBonuses.length != elementsCount) revert NonEqualArrays();
        if (_elementNames.length != elementsCount) revert NonEqualArrays();

        for (uint256 i = 0; i < _elementIds.length; i++) {
            uint24 _elementId = _elementIds[i];
            elementURI[_elementId].elementTypeId = _typeIds[i];
            elementURI[_elementId].masteryPoints = _masteryPoints[i];
            elementURI[_elementId].masteryBonus = _masteryBonuses[i];
            elementURI[_elementId].elementName = _elementNames[i];
        }
    }

    // === overrides ===
    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256) internal virtual override {
        // if (IMorphElements(MorphContract).isElementMorphed(startTokenId)) revert TokenMorphed();
        if (isElementMasteryLocked.get(startTokenId)) revert TokenMasteryLocked();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // for get same extraData after token transfers
    function _extraData(address, address, uint24 previousExtraData) internal view virtual override returns (uint24) {
        return previousExtraData;
    }

    // too avoid stack deep error
    function tokenURIPart(uint256 tokenId) private view returns (string memory) {
        string memory tokenHash = bytes32ToString(tokenIdToHash[tokenId]);
        uint256 _elementId = uint256(elementId(tokenId));

        return string(
            abi.encodePacked(
                '"element_id": "',
                _elementId.toString(),
                '", ',
                '"token_hash": "',
                tokenHash,
                '", ',
                '"image": "',
                animationURI,
                "api/image/",
                tokenId.toString(),
                '", ',
                '"animation_url": "',
                animationURI,
                "preview/",
                _elementId.toString(),
                "/",
                tokenHash,
                '", '
            )
        );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 _elementId = uint256(elementId(tokenId));
        ElementURIStruct memory _elementURI = elementURI[uint24(_elementId)];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "',
                        _elementURI.elementName,
                        " #",
                        tokenId.toString(),
                        '", ',
                        '"collection_name": "OnChain Alchemy", ',
                        '"description": "Onchain Alchemy is an on-chain generative art experience! Join the Citadel of Alchemists as an acolyte in a mystical world to craft & merge elements. Rise through the ranks to become a master alchemist and uncover the rarest elements!", ',
                        tokenURIPart(tokenId),
                        '"website": "https://onchainalchemy.io", ',
                        '"attributes": [{"trait_type": "Element Type", "value": "',
                        _elementURI.elementName,
                        '"}, ',
                        '{"trait_type": "Element Limit", "value": "',
                        elementLimits[uint24(_elementId)].limit.toString(),
                        '"',
                        "}]}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // util
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(64 + 2); // 64 hex characters + "0x" prefix

        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < 32; i++) {
            str[2 + i * 2] = hexChars[uint8(_bytes32[i] >> 4)];
            str[3 + i * 2] = hexChars[uint8(_bytes32[i] & 0x0f)];
        }

        return string(str);
    }
}
