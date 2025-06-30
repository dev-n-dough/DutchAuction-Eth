// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {DutchAuction} from "../src/DutchAuction.sol";

contract DeployAuction is Script{
    DutchAuction auction;
    
    function run() external returns(DutchAuction){
        vm.startBroadcast();
        auction = new DutchAuction();
        vm.stopBroadcast();
        return auction;
    }
}
