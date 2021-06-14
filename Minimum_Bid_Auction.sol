//MINIMUM BID AUCTION - minimum bid concept applies here, ie. the amount bid by the bidder needs to be greater than the minimum bid amount

pragma solidity ^0.6.4;

contract Auction {
    address internal auction_owner;
    uint256 public auction_start; 
    uint256 public auction_end; 
    uint256 public highestBid; 
    uint256 public startBid; 
    address public highestBidder;
    uint256 nftID;
    
    
    enum auction_state {
        CANCELLED, STARTED
    }
    
    address[] bidders;
    mapping(address => uint) public bids;
    auction_state public STATE;
    
    modifier an_ongoing_auction() { 
        require(now <= auction_end,"The auction has ended");
        _;
    }
    
    modifier only_owner() { 
        require(msg.sender == auction_owner,"Only owner can perform this auction");
        _;
    }
    
    function get_owner() public view returns(address) { 
        return auction_owner;
    } 
    
    
    event BidEvent(address indexed highestBidder, uint256 highestBid);
    event WithdrawalEvent(address withdrawer, uint256 amount);
    event CanceledEvent(string message, uint256 time);
    event EndedAuction(string message,uint256 amount, uint256 time,address winner,uint256 tokenId);
    
    
    
    constructor (uint _biddingTime, address _owner,uint256 _nftID,uint256 _startBid) public {
        auction_owner = _owner;
        auction_start = now;
        auction_end = auction_start + _biddingTime* 1 seconds;
        STATE = auction_state.STARTED;
        nftID = _nftID;
        startBid = _startBid;
    } 
    
    function bid() public payable returns (bool){ 
        require(now <= auction_end,"The auction has ended, cannot place bids");
        require(msg.sender!=auction_owner,"Auction owner cannot participate in the auction");
        uint256 newBid = bids[msg.sender] + msg.value;
        require(newBid>=startBid,"Bid amount is smaller than minimum bid");
        require( newBid > highestBid, "can't bid, Make a higher Bid");
    
        highestBidder = msg.sender;
        highestBid = newBid;
        bidders.push(msg.sender);
        bids[msg.sender] = newBid;
        emit BidEvent(highestBidder, highestBid);
        return true;
    } 
    function withdraw() public payable returns(bool){
        require(msg.sender!=highestBidder,"Bid winner cannot withdraw the amount");
        require(now > auction_end || STATE==auction_state.CANCELLED, "can't withdraw, Auction is still open");
        uint amount = bids[msg.sender];
        
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to withdraw Ether");
        bids[msg.sender] = 0;
        
        WithdrawalEvent(msg.sender, amount); 
        return true;
    } 
    
    function cancel_auction() public only_owner an_ongoing_auction returns (bool) {
        STATE = auction_state.CANCELLED;
        highestBid=0;
        highestBidder= address(0);
        CanceledEvent("Auction Cancelled", now); 
        return true;
    } 
    
    //get contract balance
    
    function getContractBalance() public view returns (uint) {
            return address(this).balance;
    }
    
    function end_auction() public only_owner payable returns (bool)  {    
        //THE AUCTION NEEDS TO BE ENDED IN THE REACT CODE ONCE TIME IS ELAPSED
       
        require(STATE==auction_state.STARTED,"The auction has ended already");
        (bool sent, bytes memory data) = auction_owner.call{value: highestBid}("");
       
        require(sent, "Failed to recieve Ether");
        EndedAuction("Auction Ended transferred", highestBid, now,highestBidder,nftID); 
        bids[highestBidder] = 0;
        highestBid=0;
        highestBidder= address(0);
        STATE = auction_state.CANCELLED;
        return true;
    } 
    
    function destruct_auction() external only_owner returns (bool) { 
        require(now > auction_end || STATE==auction_state.CANCELLED, "You can't destruct the contract,The auction is still open");
        for (uint i = 0; i < bidders.length; i++)
        {
        assert(bids[bidders[i]] == 0);
        }
        
        //check if the contract has balance in it before destructing
        
        require(address(this).balance==0,"The contract still has balance ,cannot be destroyed");
        selfdestruct(payable(auction_owner)); 
        return true;
        } 
} 
