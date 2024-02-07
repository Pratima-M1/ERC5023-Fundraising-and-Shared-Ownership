// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./interfaces/IERC5023.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MappingToArrays.sol";

contract FundRaisingContract is ERC721URIStorage, Ownable, IERC5023 {
    string public baseURI;
    
    uint256 internal _currentIndex;
    MappingToArrays mappingToArray;

      // Struct to store fundraising details for each asset
    struct FundRaisingDetails {
        uint256 totalShares;
        uint256 sharesSold;
        uint256 assetPrice;
        bool assetLocked;
    }

    struct SharedOwnersDetails {
        address sharedowner;
        uint256 assetId;
        uint256 sharedId;
        uint256 shareHolded;
    }
    // Mapping to store the voting status for each token
    mapping(uint256 => mapping(uint256 => bool)) private _votingStatus;

    // Mapping to track fundraising details for each asset
    mapping(uint256 => FundRaisingDetails) private _FundRaisingDetails;

    mapping(uint256 => address) assetOwners;
    mapping(uint256 => bool) _votingOpen;

    mapping(uint256 => mapping(uint256 => SharedOwnersDetails)) sharedOwners;
    mapping(uint256=>address)_owners;
     mapping(uint256 => bool) _saleIsOpen;
     mapping(uint256=>bool)_sharedTokensLocked;
     mapping(uint256=>uint256)_balances;

    constructor(
        string memory _name,
        string memory _symbol,
        address _mappingTOArray
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
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
        require(to != address(0), "ERC5023: mint to the zero address");
        require(
            _exists(tokenIdToBeShared),
            "ERC5023: token to be shared must exist"
        );
        require(
            ownerOf(tokenIdToBeShared) == msg.sender,
            "ERC5023: sender must be the owner of the token"
        );

        string memory _tokenURI = tokenURI(tokenIdToBeShared);
        _mint(to, _currentIndex);
        _setTokenURI(_currentIndex, _tokenURI);

        emit Share(msg.sender, to, _currentIndex, tokenIdToBeShared);

        return _currentIndex++;
    }

    function registerAsset(address Investor) public {
        require(Investor != address(0), "Investor: not a valid address");
        _mint(Investor, _currentIndex);
        _votingOpen[_currentIndex] = false;
        assetOwners[_currentIndex]=Investor;
        _owners[_currentIndex]=Investor;
        _currentIndex++;
    }

    function registerAssetForFundraising(uint256 tokenId,uint256 assetPrice, uint256 totalShares)
        external
        onlyOwner
    {
       require(_exists(tokenId), "ERC5023: token must exist");
        require(
            !_FundRaisingDetails[tokenId].assetLocked,
            "FundRaising: asset is already locked for fundraising"
        );
        _FundRaisingDetails[tokenId] = FundRaisingDetails(
            totalShares,
            0,
            assetPrice,
            true
        );
    }

    function buyShares(
        address to,
        uint256 tokenIdToBeShared,
        uint256 numberOfShares
    ) external  {
       require(
            _exists(tokenIdToBeShared),
            "ERC5023: token must exist"
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
       //transfer the share price to the owners address from buyer
        share(to, tokenIdToBeShared);
        _owners[_currentIndex]=to;
        _sharedTokensLocked[_currentIndex]=true;
      
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
   
      function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function distributeIncome(uint256 tokenId, uint256 totalIncome) external view  onlyOwner {
    require(_exists(tokenId), "FundRaising: token must exist");
    require(!_votingOpen[tokenId], "FundRaising: Voting is not open");
    require(_saleIsOpen[tokenId], "FundRaising: Sale is not open");
    // Get the total number of shared owners for the given token
    uint256 totalSharedOwners = _FundRaisingDetails[tokenId].sharesSold;
    // Keep track of shared token IDs//mappingToArrays
    uint256[] memory sharedTokenIds = mappingToArray.getArray(tokenId);
    // Calculate income per share
    uint256 incomePerShare = totalIncome / totalSharedOwners;
    // Distribute income to shared owners
    for (uint256 i = 0; i < totalSharedOwners; i++) {
        uint256 sharedTokenId = sharedTokenIds[i];
        address sharedOwner = sharedOwners[tokenId][sharedTokenId].sharedowner;
        uint256 sharesHeld = sharedOwners[tokenId][sharedTokenId].shareHolded;
        // Calculate income for the shared owner based on their shares
        uint256 ownerIncome = incomePerShare * sharesHeld;
        //add the income to owner balance//transfer the amount from buyer to seller address
        //also all dues and reward claims to be taken care of
    }
}

function transferToken(uint256 sharedTokenId,address to)public view {
    require(!_sharedTokensLocked[sharedTokenId],"ERC5023:cannot transfer the token");
    revert("If any due fees are there");//allow only if all dues are paid and rewards/claims fees of the current owner is claimed
}

}
