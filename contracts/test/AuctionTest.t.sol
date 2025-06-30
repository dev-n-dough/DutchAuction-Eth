// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test,console} from "forge-std/Test.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {DeployAuction} from "../script/DeployAuction.s.sol";
import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";

contract AuctionTest is Test{
    DutchAuction auction;
    DeployAuction deployer;
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");

    function setUp() public {
        deployer = new DeployAuction();
        auction = deployer.run();
    }

    function testOwner() public view{
        console.log("Auction owner : ",auction.owner());
        console.log("Deployer address : ", address(deployer));
        console.log("Testing contract address : ", address(this));
        console.log("msg.sender : ", msg.sender);
    }

    // msg.sender == owner of auction contract 👆

    function testCreateAuction() public{
        vm.prank(auction.owner()); // e without this, msg.sender into the auction will become the test contract
        auction.createAuction();

        assert(auction.getTokenCounter() == 1);
        assert(auction.getNftData(0).state == DutchAuction.AuctionState.OPEN);
    }

    function testBuy() public{
        uint256 currentTime = block.timestamp;
        testCreateAuction(); // this creates an nft with id = 0
        vm.warp(currentTime + 100);
        uint256 price = auction.getPrice(0);

        hoax(bob, 1 ether);
        uint256 initialUserBalance = bob.balance;
        auction.buy{value : price + 0.5 ether}(0);
        uint256 finalUserBalance = bob.balance;
        assert(initialUserBalance - finalUserBalance == price); // money is getting deducted AND refund works
        assertEq(auction.ownerOf(0), bob);
    }
}