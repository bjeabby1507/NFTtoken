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
    function declareAnimal (string memory tokenURI , string memory name) onlyBreeder 
        public
        returns (uint256)
    {
        //features memory newfeatures = features(nom,rand() % 2000,rand() % 2000,rand() % 2000); // btw 0 and 2000
        features memory newfeatures = features(name,random()/10,random()+5,random()-23); // btw 0 and 2000
        _tokenIds.increment();

        // new token
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId); // mint to the caller
        _setTokenURI(newItemId, tokenURI);

        breederRegister[newItemId] = msg.sender; // id => owner
        characteristic[newItemId] = newfeatures; // id => feature

        return newItemId;
    }
    function seeFeatures(uint256 tokenId) 
        public view 
        returns (string memory , uint256 , uint256 , uint256 )
    {
        return (characteristic[tokenId].name, characteristic[tokenId].PV, characteristic[tokenId].ATK, characteristic[tokenId].DEF );
    }
    
    function deadAnimal(uint256 tokenId)
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

    mapping (address => uint256) wanteedToken;
    address payable[] wanter;
    function wantTokenNb(uint256 token) onlyBreeder external returns(bool success) { // sign for the wanted token
        require(Auction_Token[token].tokenId,'not on auction');
        wanteedToken[msg.sender] = token;
        wanter.push(payable(msg.sender));
        return true;
    }

    fallback() external payable {
        //emit GotPaid(msg.sender,msg.value);
        if(IsIn(wanter, msg.sender)){
            uint256 token = wanteedToken[msg.sender];
            if(Auction_Token[token].tokenId){
                bidOnAuction(token);
            }
            else{
                msg.sender.sendValue(msg.value);
                //emit Refund(msg.sender,msg.value);
            }
        }
        else{
            msg.sender.sendValue(msg.value); // send back exces funds
            //emit Refund(msg.sender,msg.value);
        }
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
        uint256 onewei = 1 wei;
        Auction memory newauction = Auction(newId,true, msg.sender,betstart*onewei,biddingTime,users,0,address(0),close,false);
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
        internal
        returns(bool bet)
    {
        //msg.sender.transfer(msg.value);
        require(now <= Auction_Token[tokenId].canceled, "end");
        require(!Auction_Token[tokenId].completed, "reward end");
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
    /** 
    function getIndex(address payable[] memory name, address addr) internal pure returns(uint256) {
        for(uint256 i = 0 ; i<name.length ; i++) {
            if( name[i] == addr) {
            return i;
        }
    }
    }
    */
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
    function claimByForce(uint256 tokenId) onlyAdmin
        external
        returns (bool)
    {
        require(Auction_Token[tokenId].tokenId,'on auction');
        Auction_Token[tokenId].canceled = now;
    }

    function claimAuction(uint tokenId) onlyBreeder
        external 
        returns(bool success) 
    {
        require(now >= Auction_Token[tokenId].canceled, "not ended");
        require(!Auction_Token[tokenId].completed, "reward ended");
        require(Auction_Token[tokenId].highestBidder == msg.sender);

        _approve(msg.sender, tokenId);
        transferFrom(Auction_Token[tokenId].owner,msg.sender,tokenId) ;
        Auction_Token[tokenId].completed = true;

        // payment
        uint256 pay = Auction_Token[tokenId].highestBid;
        Auction_Token[tokenId].owner.sendValue( pay);
        delete wanteedToken[msg.sender];
        delete Auction_Token[tokenId].bidders[msg.sender];
        Claimed(Auction_Token[tokenId].owner, msg.sender, tokenId);
        return true;
    }

    function withdrawPayment(uint tokenId) onlyBreeder
        external
        returns(bool success)
    {
        require(Auction_Token[tokenId].completed, "reward not ended");
        require(IsIn(Auction_Token[tokenId].users,msg.sender)); // as bet in this auction
        // refund
        uint256 pay = Auction_Token[tokenId].bidders[msg.sender];
        msg.sender.sendValue(pay);
        Auction_Token[tokenId].tokenId = false;
        delete Auction_Token[tokenId].bidders[msg.sender]; // remove bidder from list
        delete wanteedToken[msg.sender];
        // remove bidder from list payable , delate and shift to the left
        uint Arrlength = Auction_Token[tokenId].users.length;
        //uint index = getIndex(Auction_Token[tokenId].users,msg.sender);
        uint256 index;
        for(uint256 i = 0 ; i<Arrlength-1 ; i++) {
            if( Auction_Token[tokenId].users[i] == msg.sender) {
                index = i;
        }}
        //address payable element = Auction_Token[tokenId].users[index];
        for(uint256 ip = index; ip<Arrlength-1; ip++){
            Auction_Token[tokenId].users[ip] = Auction_Token[tokenId].users[ip+1];
        }
        delete Auction_Token[tokenId].users[Arrlength-1];

        // delete from ongoing auction
        if (Auction_Token[tokenId].users.length == 0){
            delete auctions[Auction_Token[tokenId].number-1];
            delete Auction_Token[tokenId];
            openAuction.decrement();
        }
        return true;
    }

    /** 
    struct Fight {
        uint256 code;
        address payable F1;
        uint Token_F1;
        address payable F2;
        uint Token_F2;
        uint256 bet;
        bool start;
        bool full;
    }
    mapping(uint256 => Fight) Fight_Token;
    event FightCreated(address add, uint256 code);
    Counters.Counter FightNumber;
    Fight[] public list_Fight;

    function proposeToFight(uint256 tokenId) onlyBreeder external returns(bool success){
        require(approve(msg.sender,tokenId),'appartenance');
        require(!Fight_Token[tokenId].start;'ne s est pas engager');
        FightNumber.increment();
        uint256 code = FightNumber.current();
        Fight memory newfight = Fight(code,msg.sender,tokenId,address(0),0,msg.value,true,false);
        Fight_Token[code] = newfight;
        FightCreated(msg.sender,code);
        list_Fight.push(newfight);
        return true;
    }

    function agreeToFight(uint256 code,uint256 tokenId) onlyBreeder external returns(bool success){
        require(Fight_Token[code].start, 'il existe un combat');
        require(approve(msg.sender,tokenId),'appartenance');
        require(Fight_Token[code].bet == msg.value,'même mise');
        require(Fight_Token[code].full is false,'pas d adversaire');
        Fight_Token[code].F2=msg.sender;
        Fight_Token[code].Token_F2=tokenId;
        Fight_Token[code].full=true;
        return true;
    }

    // function automatique de combat
    function OnFight(uint256 code) onlyBreeder external returns(bool success){
        require(Fight_Token[code].full,'full is true');
        cara1=characteristic[Fight_Token[code].Token_F1];
        cara2=characteristic[Fight_Token[code].Token_F2];
        total1 = (cara1.PV+cara1.ATK+cara1.DEF)*(rand()%100):
        total2 = (cara2.PV+cara2.ATK+cara2.DEF)*(rand()%100):
        if (total1 > total2) {
            _burn(Fight_Token[code].Token_F1);
            // send token to the winner
            Fight_Token[code].F1.send(Fight_Token[code].bet*1,8);
        },
        else {
            _burn(Fight_Token[code].Token_F2);
            // send token to the winner
            Fight_Token[code].F2.send(Fight_Token[code].bet*1,8);
        }
        return true;
    }
    */
}