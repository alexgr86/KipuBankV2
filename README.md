# kipu-bank

![eth_img](images/Ethereum_logo_translucent.png)

## References
- https://wizard.openzeppelin.com/
- https://github.com/DigiCris/EthKipuPM.git

## Contract Information
### Contract address
`0x815427e27cb2532c16f3302f18dfbd7339806258`
[Kipu-Bank V2 - smart contract](https://sepolia.etherscan.io/address/0x815427e27cb2532c16f3302f18dfbd7339806258)

- Mock ARSS Token 0xbc6181db678886bcb01a48948b1aa08c2057b50d 
- Mock Oracle 0xf7d30f5daf12405dff3a4e56c6170ebe1effddfe
- KipuBank V2 0x815427e27cb2532c16f3302f18dfbd7339806258


## Improvemets
- Suggested corrections were made.
- Multitoken support was added to a custom token, stable ARS.
- Oracle query was added (mock with stable ARS).
- Administrative functions such as pause and unpause were added.

## Description
This is a smart contract that functions as a bank. Any user can deposit and withdraw ETH according to the rules established in the contract.

While it is intended for educational purposes, it serves as an approximation of a bank implementation using smart contracts.

## Rules
- Any user (a wallet with an address) can deposit into the bank

- Only the owner of the account (each address used to deposit) can withdraw their own ETH

- There is a maximum amount that can be withdrawn per transaction

- There is a maximum limit on how much the bank can store

## Contract Interaction

### Functions

#### deposit:
The wallet can deposit funds as long as it does not exceed the global limit defined in the contract.

#### withdrawValue:
The wallet can withdraw its previously deposited ETH, as long as it does not exceed the maximum amount allowed per transaction.

#### getBalance:
Allows the wallet to check its current account balance in KipuBank.

#### getBankCap:
This function allows checking the maximum limit that the contract can store.

#### getWithdrawLimit: 
Maximum amount allowed per withdrawal.

## Steps Deploy

1. Select the network to deploy

![eth_img](images/injected_provider.png)

2. Verify that the selected network is correct

![eth_img](images/verify_sepolia.png)

3. Sign with the selected provider

![eth_img](images/firma_deploy.png)

3. Obtain contract address


