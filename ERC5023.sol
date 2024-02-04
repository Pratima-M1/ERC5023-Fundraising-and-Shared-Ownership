// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./interfaces/IERC5023.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC5023 is ERC721URIStorage, Ownable, IERC5023 /* EIP165 */ {
    using Address for address;
  struct Asset{
    address owner;
    uint256 tokenId;
    uint256 noofShares;
    address []sharedowners;
  }
    string baseURI;

    uint256 internal _currentIndex;
    mapping (uint256=>bool) _tokenExists;
    mapping(uint256=>Asset) _assets;
    mapping(uint256=>uint256) noOfShares;
    mapping(uint256=>bool) tokenLocked;

    constructor() ERC721("Sharable NFT","SHNFT")Ownable(msg.sender) { _currentIndex=1;}

    function mint(address account, uint256 tokenId) external onlyOwner {
        _mint(account, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) external {
        _setTokenURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
      function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenExists[tokenId];
    }

//mint a token  when owner adds the asset in owner address
function addAsset(address owner,uint256 _noOfShares)external {
    require(owner!=address(0),"Invalid address");
    _mint(owner,_currentIndex);
    address [] memory sharedOwners=new address[](1);
    sharedOwners[0]=owner;
    _assets[_currentIndex]=Asset(owner,_currentIndex,_noOfShares,sharedOwners);
    noOfShares[_currentIndex]=_noOfShares;
    _tokenExists[_currentIndex]=true;
    _currentIndex++;
}

//share asset //CHANGE IT TO TOTALsUPPLY OF MAINASSET
    function shareAsset(address to, uint256 tokenIdToBeShared,uint256 _noOfShares) external{
        require(to!=_assets[tokenIdToBeShared].owner,"shared owner should not be the token owner");
        require(noOfShares[tokenIdToBeShared]>0&&_noOfShares<=noOfShares[tokenIdToBeShared],"shares are not sufficient");
       uint256 shareId=share(to,tokenIdToBeShared);
        _assets[shareId].sharedowners.push(to);
        noOfShares[shareId]=_noOfShares;
        noOfShares[tokenIdToBeShared]=noOfShares[tokenIdToBeShared]-_noOfShares;
        }

//Shares the mainAsset token with shared owners with number of shares he/she wants to buy
 function share(address to, uint256 tokenIdToBeShared) public returns(uint256 newTokenId) {
      require(to != address(0), "ERC721: mint to the zero address");
      require(_exists(tokenIdToBeShared), "ShareableERC721: token to be shared must exist");
      
      require(msg.sender == ownerOf(tokenIdToBeShared), "Method caller must be the owner of token");

      string memory _tokenURI = tokenURI(tokenIdToBeShared);
     uint256 sharedId=_currentIndex;
      _mint(to, sharedId);
      _setTokenURI(sharedId, _tokenURI);
      emit Share(msg.sender, to, sharedId, tokenIdToBeShared);
      tokenLocked[_currentIndex]=true;
      _tokenExists[sharedId]=true;
      _currentIndex++;
      return sharedId;
  }

  function balanceOf(uint256 tokenId)public view returns(uint256){
    require(_exists(tokenId),"token doesnot exists");
    return noOfShares[tokenId];
  }

  function getAllSharedOwners(uint256 tokenId)public view returns(address [] memory ){
    return _assets[tokenId].sharedowners;
  }

    // Override transfer functions to restrict transfer of shared tokens without owner's consent

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721,IERC721){
      /*  require(msg.sender == ownerOf(tokenId) || _msgSender() == getApproved(tokenId) || isApprovedForAll(ownerOf(tokenId), _msgSender()), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: can only transfer owned token");
        _transfer(from, to, tokenId);*/
        require(_exists(tokenId),"token doesnot exists");
        require(!tokenLocked[tokenId],"cannot transfer shared token");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721,IERC721) {
       /* require(msg.sender == ownerOf(tokenId) || _msgSender() == getApproved(tokenId) || isApprovedForAll(ownerOf(tokenId), _msgSender()), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: can only transfer owned token");
        safeTransferFrom(from, to, tokenId, _data);*/

         require(_exists(tokenId),"token doesnot exists");
        require(!tokenLocked[tokenId],"cannot transfer shared token");
        safeTransferFrom(from, to, tokenId,_data);
    }
}
