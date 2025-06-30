// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract DutchAuction is ERC721, Ownable{
    // put up something for auction, let a NFT
    // when auction starts, keep its price as `x`
    // with time, price will decrease linearly
    // at any point in time, any user can buy that NFT for this price

    // constructor - start price, duration, priceDecrement rate

    // create a single auction
    // start trigger - startAuction() - mint NFT, give this auction an ID => maybe keep this onlyOwner
    // getter fn - get the current price - do maths - getPrice()
    // buy the NFT - put an end to action - buy(id)

    error DutchAuction__AuctionClosed();
    error DutchAuction__AuctionExpired();
    error DutchAuction__InsuffientFundsSent();

    uint256 private s_startPrice = 1e17; // 0.1 ether
    uint256 private s_duration = 180; // 180 seconds => 3 mins
    uint256 private s_decrement = 1e14; // 0.0001
    uint256 private s_tokenCounter = 0; // NFT id's to be provided while minting
    string private s_name = "Dutch Auction NFT";
    string private s_symbol = "DAN"; // dutch auction NFT

    struct nftData{
        uint256 startTime; // to check expiry and calc price
        AuctionState state; // flag to check if auction is over
    }

    mapping (uint256 id => nftData data) s_idToData;

    enum AuctionState {OPEN, CLOSED}

    modifier checkAuctionState(uint256 id){
        AuctionState state = s_idToData[id].state; // if this id dont exist in mapping, it will error out, else if would have its state set to either one
        if(state == AuctionState.CLOSED){
            revert DutchAuction__AuctionClosed();
        }
        _;
    }

    constructor() Ownable(msg.sender) ERC721(s_name, s_symbol){}

    function createAuction() external onlyOwner{
        // mint NFT to this contract
        _mint(address(this), s_tokenCounter);
        uint256 id = s_tokenCounter++;
        s_idToData[id] = nftData(
            uint256(block.timestamp),
            AuctionState.OPEN
        );
    }

    function getPrice(uint256 id) public view checkAuctionState(id) returns(uint256 price){
        uint256 timePassed = block.timestamp - s_idToData[id].startTime;
        if(timePassed >= s_duration){
            return 0; // zero price signifies that auction has ended
        }
        price = s_startPrice - (timePassed * s_decrement);
    }

    function buy(uint256 id) external payable checkAuctionState(id){
        uint256 timePassed = block.timestamp - s_idToData[id].startTime;
        if(timePassed >= s_duration){
            s_idToData[id].state = AuctionState.CLOSED;
            revert DutchAuction__AuctionExpired();
        }
        uint256 currentPrice = getPrice(id); 
        if(currentPrice == 0){ // e auction has expired, this would never happen because of the modifier and the above if statement, but just to be extra sure I have made this check again
            revert DutchAuction__AuctionExpired();
        }
        if(msg.value < currentPrice){
            revert DutchAuction__InsuffientFundsSent();
        }
        // auction is open, money sent is sufficient :
        // send nft, mark auction as closed
        s_idToData[id].state = AuctionState.CLOSED;
        _transfer(address(this),msg.sender, id);
        uint256 refundAmount = msg.value - currentPrice;
        if(refundAmount != 0){
            (bool success,) = payable(msg.sender).call{value : refundAmount}("");
            require(success);
        }
    }

    function withdraw() external onlyOwner{
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    function getTokenCounter() public view returns(uint256){
        return s_tokenCounter;
    }

    function getNftData(uint256 id) public view returns(nftData memory){
        return s_idToData[id];
    }

    fallback() external payable{}
    receive() external payable{}
}
