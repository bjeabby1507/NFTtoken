pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract farmToken is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using Address for address payable;
    using Address for address;

    using SafeMath for uint256;

    string public _name = "FarmItem";
    string public _symbol = "FRM";
    address public Owner;

    constructor() public ERC721(_name, _symbol) {
        Owner = msg.sender;
    }

    modifier onlyAdmin {
    require(Owner == msg.sender);
        _;
    }
    
    mapping(address => bool) register; // Create a mapping to track breeder
    Counters.Counter public BreederNumber;
    mapping(uint256 => address) breederRegister;  // each id is linked to an owner address : breederRegister[token] = address
    event registered(address addr, bool status);
    //event breederRegistered(address addr, uint256 token);

    struct features{
        string name;
        uint256 PV;
        uint256 ATK;
        uint256 DEF;
    }

    mapping(uint256 => features) characteristic;  //  each id is linked to a feature

    function registerBreeder(address _add) onlyAdmin 
        external
    {
        require(!register[_add], "not subscribe.");
        register[_add] = true;
        BreederNumber.increment();
        emit registered(_add, true);
    }

    modifier onlyBreeder {
    require(register[msg.sender]);
        _;
    }

    // generate random number for characteristic
    // maybe not that safe , can be tampered ? use an Oracle?
    function random() 
        private view 
        returns (uint256) 
    {
        //uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, now))); // now (uint): current block timestamp (alias for block.timestamp)
        return uint256(keccak256(abi.encodePacked(block.difficulty, now))) % 2001; // between 0 and 2000
        //return uint8(uint256(keccak256(block.timestamp, block.difficulty))%2001); // integer between 0 and 2000 , block.timestamp is assigned by the miner whenever he confirms the transaction
    } 

    // use URI : https://my-json-server.typicode.com/bjeab1507/NFTtoken/
    function declareAnimal (string calldata tokenURI ,string calldata name) onlyBreeder
        external
        returns (uint256)
    {
        //features memory newfeatures = features(nom,rand() % 2000,rand() % 2000,rand() % 2000); // btw 0 and 2000
        features memory newfeatures = features(name,random(),random(),random()); // btw 0 and 2000
        _tokenIds.increment();

        // new token
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId); // mint to the caller
        _setTokenURI(newItemId, tokenURI);

        breederRegister[newItemId] = msg.sender; // id => owner
        characteristic[newItemId] = newfeatures; // id => feature

        return newItemId;
    }

    /** 
    function seeFeatures(uint256 tokenId) 
        public view 
        returns (string memory , uint256 , uint256 , uint256 )
    {
        return (characteristic[tokenId].name, characteristic[tokenId].PV, characteristic[tokenId].ATK, characteristic[tokenId].DEF );
    }
    */

    function deadAnimal(uint256 tokenId) onlyBreeder 
        internal 
        returns(bool success)
    {
        //delete breederRegister[tokenId];
        //delete characteristic[tokenId];
        require(_exists(tokenId), "not minted");
        _burn(tokenId);
        return true;
    }

    function breedAnimal(uint256 tokenId_1, uint256 tokenId_2, string calldata tokenURI, string calldata new_name) onlyBreeder
        external 
        returns (uint256)
    {
        require(_isApprovedOrOwner(msg.sender,tokenId_1),"not yours"); //tokenId_1 does not belongs to caller
        require(_isApprovedOrOwner(msg.sender,tokenId_2),"not yours");

        //merge features
        //uint256 PV= (characteristic[tokenId_1].PV+ characteristic[tokenId_2].PV)/2;
        //uint256 ATK= (characteristic[tokenId_1].ATK+ characteristic[tokenId_2].ATK)/2;
        //uint256 DEF= (characteristic[tokenId_1].DEF+ characteristic[tokenId_2].DEF)/2;
        features memory newfeaturesmix = features(new_name,(characteristic[tokenId_1].PV+ characteristic[tokenId_2].PV)/2,(characteristic[tokenId_1].ATK+ characteristic[tokenId_2].ATK)/2,(characteristic[tokenId_1].DEF+ characteristic[tokenId_2].DEF)/2); // btw 0 and 2000
        //features memory newfeaturesmix = features(new_name,PV,ATK,DEF);

        // new token
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId); // mint to the caller
        _setTokenURI(newItemId, tokenURI);

        breederRegister[newItemId] = msg.sender; // id => owner
        characteristic[newItemId] = newfeaturesmix; // id => feature
        
        return newItemId;
    }

    event GotPaid(address addr, uint256 value);
    event Refund(address addr,uint256 value);
    event ValueReceived(address user, uint amount);
    /** 
    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }
    */

    fallback() external payable {
        // send back exces funds
        emit GotPaid(msg.sender,msg.value);
        msg.sender.sendValue(msg.value);
        emit Refund(msg.sender,msg.value);
    }
    //Auction 

    Counters.Counter AuctionNumber ; // n°Auction
    Counters.Counter public openAuction ; // number of openAuction
    Auction[] public auctions; // list of ongoing Auction

    struct Auction {
        uint256 number;
        bool tokenId; //token used
        address payable owner;
        uint256 start;
        uint256 nbdays;
        //address payable[] bidders; // bidders[addr] = bid
        mapping (address=> uint256) bidders;
        address payable[] users;
        uint256 highestBid;
        address highestBidder;
        uint256 canceled;
        bool completed;
    }

    event AuctionCreated(address owner, uint256 numAuctions);
    event Bid(address bidder, uint256 bid, address highestBidder, uint256 highestBid);
    event Claimed(address withdrawer, address claimer, uint256 token);

    mapping (uint256 => Auction) Auction_Token ;// each id is link to an Auction instance

    /**
    function allAuctions() public view returns (Auction[] memory) {
        return auctions;
    }
     */

    // betstart = 1000000000000000000 = 1ETH
    function createAuction(uint256 tokenId, uint256 betstart) onlyBreeder
        external 
        returns(bool success)
    {
        require(_isApprovedOrOwner(msg.sender,tokenId),"not yours");
        require(!Auction_Token[tokenId].tokenId,'already on auction');

        // new auction
        AuctionNumber.increment();
        uint256 newId = AuctionNumber.current();
        //address [] memory biddersList;
        address payable[] memory users;
        uint256 biddingTime = 2;
        uint256 close = now + biddingTime * 1 days;
        Auction memory newauction = Auction(newId,true, msg.sender,betstart,biddingTime,users,0,address(0),close,false);
        Auction_Token[tokenId] = newauction;
        openAuction.increment();
        auctions.push(newauction);
        //auctions.push(AuctionNumber);
        //auctions[AuctionNumber] = newauction;
        AuctionCreated(msg.sender, newId);
        return true;
    }
    /** 
    function seeAuction(uint256 tokenId) 
        external view 
        returns (uint256,address payable , uint256 , uint256 , address payable[] memory , uint256 , address )
    {
        require(Auction_Token[tokenId].tokenId,'on auction');
        return (Auction_Token[tokenId].number, Auction_Token[tokenId].owner, Auction_Token[tokenId].start, Auction_Token[tokenId].nbdays, Auction_Token[tokenId].users,Auction_Token[tokenId].highestBid,Auction_Token[tokenId].highestBidder);
    }
    */

    //mapping (address => uint256) fundsByBidders;
    // is a payable function, when Ethers is send to the function, this Ether will be added to the balance of the contract
    function bidOnAuction(uint256 tokenId) onlyBreeder
        external payable 
        returns(bool bet)
    {
        //msg.sender.transfer(msg.value);
        require(now <= Auction_Token[tokenId].canceled, "end");
        require(Auction_Token[tokenId].completed, "reward end");
        require(msg.value > 0, "send some ether");
        require(Auction_Token[tokenId].tokenId,'on auction');
        require(msg.value > Auction_Token[tokenId].start);
        uint256 currentHighBid = Auction_Token[tokenId].highestBid;
        uint256 bid = 0;
        if (IsIn(Auction_Token[tokenId].users,msg.sender)){ // has alredy bet on this auction
            uint256 newbid = Auction_Token[tokenId].bidders[msg.sender] + msg.value;
            Auction_Token[tokenId].bidders[msg.sender] = newbid; // bidders => bid
            if(getHighestBid(newbid,currentHighBid )){
                Auction_Token[tokenId].highestBid = newbid;
                Auction_Token[tokenId].highestBidder = msg.sender;
                bid = newbid;
            }
        }
        else {
            Auction_Token[tokenId].users.push(payable(msg.sender));
            Auction_Token[tokenId].bidders[msg.sender] = msg.value; // bidders => bid
            if(getHighestBid(msg.value,currentHighBid )){ // ffrst bid in this auction
                Auction_Token[tokenId].highestBid = msg.value;
                Auction_Token[tokenId].highestBidder = msg.sender;
                bid = msg.value;
            }
            else{
                msg.sender.sendValue( msg.value);
            }
        }
        Bid(msg.sender, bid , Auction_Token[tokenId].highestBidder, Auction_Token[tokenId].highestBid);
        return true;
    }

    function IsIn(address payable[] memory name, address addr) internal pure returns(bool) {
        for(uint256 i = 0 ; i<name.length ; i++) {
            if( name[i] == addr) {
            return true;
        }
    }
    }
    function getIndex(address payable[] memory name, address addr) internal pure returns(uint256) {
        for(uint256 i = 0 ; i<name.length ; i++) {
            if( name[i] == addr) {
            return i;
        }
    }
    }
    function getHighestBid(uint256 bid , uint256 currentHighBid)
        internal pure
        returns (bool)
    {
        if (bid <= currentHighBid){
            return false;
        }
        else{
            return true;
        }
    }

    function claimAuction(uint tokenId) onlyBreeder
        external 
        returns(bool success) 
    {
        require(now > Auction_Token[tokenId].canceled, "not ended");
        require(!Auction_Token[tokenId].completed, "reward ended");
        require(Auction_Token[tokenId].highestBidder == msg.sender);

        _approve(msg.sender, tokenId);
        transferFrom(Auction_Token[tokenId].owner,msg.sender,tokenId) ;
        Auction_Token[tokenId].completed = true;

        // payment
        uint256 pay = Auction_Token[tokenId].highestBid;
        Auction_Token[tokenId].owner.sendValue( pay);
        Claimed(Auction_Token[tokenId].owner, msg.sender, tokenId);
        return true;
    }

    function withdrawPayment(uint tokenId) onlyBreeder
        external
        returns(bool success)
    {
        require(Auction_Token[tokenId].completed, "reward ended");
        require(IsIn(Auction_Token[tokenId].users,msg.sender)); // as bet in this auction
        // refund
        uint256 pay = Auction_Token[tokenId].bidders[msg.sender];
        msg.sender.sendValue(pay);
        delete Auction_Token[tokenId].bidders[msg.sender]; // remove bidder from list
        // remove bidder from list payable , delate and shift to the left
        uint index = getIndex(Auction_Token[tokenId].users,msg.sender);
        //address payable element = Auction_Token[tokenId].users[index];
        uint Arrlength = Auction_Token[tokenId].users.length;
        for(uint i = index; i<Arrlength-1; i++){
            Auction_Token[tokenId].users[i] = Auction_Token[tokenId].users[i+1];
        }
        delete Auction_Token[tokenId].users[Arrlength-1];

        // delete from ongoing auction
        if (Auction_Token[tokenId].users.length == 0){
            delete auctions[Auction_Token[tokenId].number];
            delete Auction_Token[tokenId];
            openAuction.decrement();
        }
        return true;
    }

    /** 
    function proposeToFight() public {

    }

    function agreeToFight() public {
        
    }
    */
}