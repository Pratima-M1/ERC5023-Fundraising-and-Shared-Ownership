// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./interfaces/IERC5023.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MappingToArrays.sol";

contract FundRaising is ERC721URIStorage, Ownable, IERC5023 {
    string public baseURI;

    uint256 internal _currentIndex;
    MappingToArrays mappingToArray;
    // Mapping to store the voting status for each token
    mapping(uint256 => mapping(uint256 => bool)) private _votingStatus;

    // Mapping to track fundraising details for each asset
    mapping(uint256 => FundRaisingDetails) private _FundRaisingDetails;

    mapping(uint256 => address) assetOwners;
    mapping(uint256 => bool) _votingOpen;

    // Struct to store fundraising details for each asset
    struct FundRaisingDetails {
        uint256 totalShares;
        uint256 sharesSold;
        bool assetLocked;
    }

    struct SharedOwnersDetails {
        address sharedowner;
        uint256 assetId;
        uint256 sharedId;
        uint256 shareHolded;
    }

    mapping(uint256 => mapping(uint256 => SharedOwnersDetails)) sharedOwners;

    constructor(
        string memory _name,
        string memory _symbol,
        address _mappingTOArray,
        string memory _baseURI
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        baseURI = _baseURI;
        mappingToArray = MappingToArrays(_mappingTOArray);
        _currentIndex=1;
    }

    function mint(address account, uint256 tokenId) external onlyOwner {
        _mint(account, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI)
        external
        onlyOwner
    {
        _setTokenURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function share(address to, uint256 tokenIdToBeShared)
        public
        returns (uint256 newTokenId)
    {
        require(to != address(0), "ERC721: mint to the zero address");
        require(
            _exists(tokenIdToBeShared),
            "ShareableERC721: token to be shared must exist"
        );
        require(
            ownerOf(tokenIdToBeShared) == msg.sender,
            "ShareableERC721: sender must be the owner of the token"
        );

        string memory _tokenURI = tokenURI(tokenIdToBeShared);
        _mint(to, _currentIndex);
        _setTokenURI(_currentIndex, _tokenURI);

        emit Share(msg.sender, to, _currentIndex, tokenIdToBeShared);

        return _currentIndex++;
    }

    function registerAsset(address Investor) public {
        require(Investor != address(0), "Invesotr: not a valid address");
        _mint(Investor, _currentIndex);
        _votingOpen[_currentIndex] = false;
        assetOwners[_currentIndex]=Investor;
        _currentIndex++;
    }

    function registerAssetForFundraising(uint256 tokenId, uint256 totalShares)
        external
        onlyOwner
    {
       require(_exists(tokenId), "ShareableERC721: token must exist");
        require(
            !_FundRaisingDetails[tokenId].assetLocked,
            "FundRaising: asset is already locked for fundraising"
        );
        _FundRaisingDetails[tokenId] = FundRaisingDetails(
            totalShares,
            0,
            true
        );
    }

    function buyShares(
        address to,
        uint256 tokenIdToBeShared,
        uint256 numberOfShares
    ) external payable {
       require(
            _exists(tokenIdToBeShared),
            "ShareableERC721: token must exist"
        );
        require(
            _FundRaisingDetails[tokenIdToBeShared].assetLocked,
            "FundRaising: asset is not locked for fundraising"
        );
        require(
            _FundRaisingDetails[tokenIdToBeShared].sharesSold +
                numberOfShares <=
                _FundRaisingDetails[tokenIdToBeShared].totalShares,
            "FundRaising: not enough shares available"
        );
        //  require(msg.value == numberOfShares * 1 ether, "ShareableERC721: incorrect amount sent");
        _FundRaisingDetails[tokenIdToBeShared].sharesSold += numberOfShares;
        if (
            _FundRaisingDetails[tokenIdToBeShared].sharesSold ==
            _FundRaisingDetails[tokenIdToBeShared].totalShares
        ) {
            _FundRaisingDetails[tokenIdToBeShared].assetLocked = true;
        }
        sharedOwners[tokenIdToBeShared][_currentIndex] = SharedOwnersDetails(
            to,
            tokenIdToBeShared,
            _currentIndex,
            numberOfShares
        );
          mappingToArray.addToMapping(tokenIdToBeShared, _currentIndex);//pushes the shared owner address to asset's shared owners array
        share(to, tokenIdToBeShared);
      
    }

    function initiateVoting(uint256 tokenId) public {
        require(_exists(tokenId), "ERC5023: token must exist");
        require(!_votingOpen[tokenId], "FundRaising:Voting already open");
        _votingOpen[tokenId] = true;
    }

    // Placeholder function for the voting system
    function vote(uint256 tokenId, uint256 sharedTokenId) external {
       require(_exists(tokenId), "ERC5023: token must exist");
        require(_votingOpen[tokenId], "FundRaising:Voting is not open");
        _votingStatus[tokenId][sharedTokenId] = true;
    }

    mapping(uint256 => bool) _saleIsOpen;

    function makeDecisionForSelling(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "FundRaising: token must exist");
        require(_votingOpen[tokenId], "FundRaising: Voting is not open");

        // Get the total number of shared owners for the given token
        uint256 totalSharedOwners = _FundRaisingDetails[tokenId].sharesSold;

        // Keep track of shared token IDs
        uint256[] memory sharedTokenIds = mappingToArray.getArray(tokenId);

        // Check if all shared owners have voted and their votes are true
        for (uint256 i = 0; i < totalSharedOwners; i++) {
            uint256 sharedTokenId = sharedTokenIds[i];
            require(
                _votingStatus[tokenId][sharedTokenId],
                "FundRaising: All shared owners must vote"
            );
        }
        _saleIsOpen[tokenId] = true;
        // Reset voting status for the next round of voting
        for (uint256 i = 0; i < totalSharedOwners; i++) {
            uint256 sharedTokenId = sharedTokenIds[i];
            _votingStatus[tokenId][sharedTokenId] = false;
        }
        // Close the voting
        _votingOpen[tokenId] = false;
    }

    function initiateSelling(address to,uint256 tokenId)public{
        require(msg.sender==assetOwners[tokenId],"FundRaising:only owner can initiate selling");
           require(_exists(tokenId), "FundRaising: token must exist");
        require(!_votingOpen[tokenId], "FundRaising: Voting is open");
          require(_saleIsOpen[tokenId], "FundRaising: Sale is not open");
          safeTransferFrom(msg.sender,to,tokenId);

    }
    mapping(uint256=>address)_owners;
      function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
}
