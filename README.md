# Fundraising Contract

The Fundraising Contract is a Solidity smart contract designed to facilitate fundraising for assets by fractionalizing ownership through ERC721 tokens. It allows asset owners to register their assets, initiate fundraising rounds, and sell shares to investors. The contract ensures transparency and fairness in the fundraising process through voting mechanisms and income distribution.

## Key Features

- **Asset Registration**: Asset owners can register their assets on the blockchain, enabling them to initiate fundraising rounds.
- **Fractional Ownership**: Investors can purchase shares of registered assets, becoming fractional owners of the asset.
- **Voting Mechanism**: The contract includes a voting mechanism to determine when fundraising rounds should end and asset sales should commence.
- **Income Distribution**: Upon completing fundraising rounds and selling shares, the contract automatically distributes income to the fractional owners based on their shareholdings.

## Usage

1. **Asset Registration**: Asset owners can register their assets by calling the `registerAsset` function, providing the investor's address and asset details.
2. **Fundraising Round**: Asset owners initiate fundraising rounds by calling the `registerAssetForFundraising` function, specifying the asset's token ID, asset price, and total shares.
3. **Buying Shares**: Investors can purchase shares of registered assets by calling the `buyShares` function, specifying the recipient's address, token ID, and the number of shares to buy.
4. **Voting**: The owner can initiate voting by calling the `initiateVoting` function to determine whether asset sales should commence.
5. **Income Distribution**: The owner can call the `distributeIncome` function to distribute income to the fractional owners based on their shareholdings.
6. **Transfer Tokens**: Fractional owners can transfer their shares to other addresses by calling the `transferToken` function, provided that all dues are settled.

## Note

This contract implements the ERC721 standard for non-fungible tokens (NFTs) and the ERC5023 standard for shared ownership. It provides a decentralized solution for fundraising and asset ownership, ensuring transparency and fairness in the process.

