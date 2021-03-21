# NFTtoken

## Installation

1) Truffle :
> Truffle is a development environment where you can easily
develop smart contracts with it’s built-in testing framework, smart contract
compilation, deployment, interactive console

```bash
npm install -g truffle
```
create a project :  
```bash
mkdir nameoffile
cd file
truffle init
```
usefull commands :
```shell
Compile: truffle compile
Migrate: truffle migrate
Test contracts: truffle test
Console : truffle console
Version : truffle version
```
* [See more](https://github.com/trufflesuite/truffle)

## Deploy to testnet with Infura
```bash
npm install @truffle/hdwallet-provider
```
* [follow instruction here](https://www.trufflesuite.com/tutorials/using-infura-custom-provider)
* link truffle to infura :

In the `truffle-config.js` 

```javascript
const HDWalletProvider = require("@truffle/hdwallet-provider");
const mnemonic = """; //#mnemonic"
```
```javascript
 networks: {
    infura: {
      provider: function() {
        //return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/paths")
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/paths")
      },
      network_id: 4
    },
```
* create a new project -ENDPOINTS => Rinkeby/Ropsten/..
* To test with testnet
* get token in a faucet

In the `2_deploy_contracts.js` : choose your metamask address as Admin address
Your account need to have enough gas and ether to deploy the contracts

```shell
# Migrate
truffle migrate --reset --network infura
```
Once the contract is migrated , you can get the contract address in the console
- In Metamask you can add a token with the contract address and the token will be displayed in your metamask
- In MyCrypto choose to interact with your contract in the given testnet , then find the abi in the `build\contracts\MyToken.json` and paste it
- Now you can interact with the contract and test it
- In Metamask send ether to the contract address with Metamsk to get token


## More
