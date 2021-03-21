# Create NFT tokens
## _farmToken, FRM_

-  create , trade your token
- use truffle , Open Zeppelin 
- test with ganache , infura , a testnet network and MyCrypto

## Methods
Some functions:
-  'BreederNumber()': gives the number of address in the list for those allowed to get token trade and fight ,
-  Owner()': give the owner address,
-  'auctions(uint256)': list of ongoig auctions by index,
-  'balanceOf(address)':gives the balance of token of an address ,
-  'name()': gives the name of the token,
-  'openAuction()': numbesrof open auction,(only breeder)
-  'ownerOf(uint256)': give the owner of token by it's id,
-  'symbol()': gives the symbol of the token,
-  'tokenByIndex(uint256)': give the owner of token by it's index ,
-  'totalSupply()':  gives the total supply of token,
-  'registerBreeder(address)': add an address to the list if it is not alredy in it (only admin)
-  'declareAnimal(string,string)': breeder can create a token,(only breeder)
-  'seeFeatures(uint256)': can see the token features, 4 features (name, PV, ATK, DEF)
-  'breedAnimal(uint256,uint256,string,string)': can mix two token and create a new creature ,(only breeder)
-  'wantTokenNb(uint256)': chose a token on auction,(only breeder)
-  'createAuction(uint256,uint256)': create auction ,(only breeder)
-  'claimByForce(uint256)': stop the auction to claim,(only admin)
-  'claimAuction(uint256)': can claim auction if winner,(only breeder)
-  'withdrawPayment(uint256)': can be refund if loser,(only breeder)
-  fallback() gets called when money is sent to this contract , and bidAuction(tokenId) is called and token is sent if the sender is a member and chose to participate to the auctiob(only breeder)
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
2) Ganache :
> Ganache acts as our local Blockchain to deploy and test the 
contract functionality locally before deploying it to a public testnet.

* [follow instruction here](https://github.com/trufflesuite/ganache) to download the .appx
* launch the application and create a Workspace with the name TDToken for example
* links Truffle to Gnache ([follow this](https://www.trufflesuite.com/docs/ganache/truffle-projects/linking-a-truffle-project)) :
* links Metamask to Gnache([follow this](https://www.trufflesuite.com/docs/ganache/truffle-projects/linking-a-truffle-project),([or this](https://medium.com/@kacharlabhargav21/using-ganache-with-remix-and-metamask-446fe5748ccf)) :
* In the `truffle-config.js` 

```javascript
module.exports = {
  networks: {
    ganache: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: 5777,       // Any network (default: none)
    }
  },
```
* Then add in the Ganache Worksplace the truffle-config js file

To test with Ganache : 
In the `2_deploy_contracts.js` : choose your Ganache address as Admin address

```javascript
var FarmBattle = artifacts.require("farmToken");
module.exports = function (deployer) {
  // deployer.deploy(#Nom, )
  deployer.deploy(FarmBattle);
};
```

```shell
# Compile 
truffle compile

# Migrate
truffle migrate --reset -- network ganache

# Test
truffle console 
# in the console 
farmToken.deployed().then((instance) => {fm = instance;})
#example :
truffle(ganache)> fm.Owner()
'0x9d40750332cE4f6e6c49D72658076A1f02Fb53f8'
truffle(ganache)> fm._name()
'FarmItem'
truffle(ganache)> fm._symbol()
'FRM'
truffle(ganache)> fm.name()
'FarmItem'
truffle(ganache)> fm.totalSupply()
BN { negative: 0, words: [ 0, <1 empty item> ], length: 1, red: null }

* other examples:
fm.registerBreeder('0x7C02fbcf80013A213C6D8B372aB8Acdc1c3bf560')
fm.BreederNumber()
fm.declareAnimal('http://my-json-server.typicode.com/abcoathup/samplenft/tokens/0','toutou')
fm.seeFeatures(1)
fm.breedAnimal(1,2,'http://my-json-server.typicode.com/abcoathup/samplenft/tokens/3','toumou')
fm.tokenURI(1)
fm.createAuction(1,1)
fm.wantTokenNb(1)
```
When contracts are deployed to the local Blockchain in Ganache
if we look at the first row from the accounts table we can see that the ETH balance 
has dropped slightly and that the number of transactions has increased above 0
1) Openzeppelin
> OpenZeppelin is a library that consists of multiple, reusable contracts, to build ERC20 or ERC721 tokens for example.

```bash
npm init
npm install @openzeppelin/contracts
```
To see how to add metadata ([follow this](https://forum.openzeppelin.com/t/create-an-nft-and-deploy-to-a-public-testnet-using-truffle/2961))

## Deploy to testnet with Infura
```bash
npm install @truffle/hdwallet-provider
```
* [follow instruction here](https://www.trufflesuite.com/tutorials/using-infura-custom-provider)
* link truffle to infura :
    truffle-config.js ==> networks
    const HDWalletProvider = require("@truffle/hdwallet-provider");
    const mnemonic = #mnemonic;
```javascript
const HDWalletProvider = require("@truffle/hdwallet-provider");
const mnemonic = """; //#mnemonic"
```
```javascript
 networks: {
    ganache: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: 5777,       // Any network (default: none)
    },
    infura: {
      provider: function() {
        //return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/290e39df33ee41b6bdbc079bd550fa7a")
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/290e39df33ee41b6bdbc079bd550fa7a")
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


## Start 
Install the dependencies and devDependencies
```sh
npm install
```
Deploy localy with Ganache or in a testnet with Infura and Test
* [Contract](https://ropsten.etherscan.io/address/0x408fcf587f770e3d1d14cd831f93cbe1076dbd35) - this is the contract if you want to create your token (Ropsten testnet) , ask us before to add you in the member list 
Contract address : 0x408fCF587F770E3D1d14Cd831f93CBe1076Dbd35

## how/example
* be added to the members
* create two tokens
* create an auction
* Or choose a token on auction with wantTokenNb , then send some ethers
* fight