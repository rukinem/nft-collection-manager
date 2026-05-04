// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftCollectionManager is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 private _nextTokenId;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public maxPerWallet;
    bool public revealed;
    string private _baseURI;
    string private _unrevealedURI;

    mapping(address => uint256) public mintedCount;

    event Minted(address indexed to, uint256 indexed tokenId);

    constructor(string memory name_, string memory symbol_, uint256 _maxSupply, uint256 _mintPrice, uint256 _maxPerWallet) ERC721(name_, symbol_) Ownable(msg.sender) {
        maxSupply = _maxSupply; mintPrice = _mintPrice; maxPerWallet = _maxPerWallet;
    }

    function mint(uint256 _quantity, string[] memory _uris) external payable nonReentrant {
        require(_nextTokenId + _quantity <= maxSupply, "Exceeds max supply");
        require(msg.value >= mintPrice * _quantity, "Insufficient payment");
        require(mintedCount[msg.sender] + _quantity <= maxPerWallet, "Exceeds max per wallet");
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _safeMint(msg.sender, tokenId);
            if (_uris.length > i) _setTokenURI(tokenId, _uris[i]);
            mintedCount[msg.sender]++;
            emit Minted(msg.sender, tokenId);
        }
    }

    function reveal(string memory _newBaseURI) external onlyOwner { _baseURI = _newBaseURI; revealed = true; }
    function setUnrevealedURI(string memory _uri) external onlyOwner { _unrevealedURI = _uri; }
    function setMintPrice(uint256 _price) external onlyOwner { mintPrice = _price; }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) { return _nextTokenId; }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) { super._beforeTokenTransfer(from, to, tokenId, batchSize); }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) { super._burn(tokenId); }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) { return super.tokenURI(tokenId); }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, ERC721Enumerable) returns (bool) { return super.supportsInterface(interfaceId); }
}