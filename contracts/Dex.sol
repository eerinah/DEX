pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./Wallet.sol";

contract Dex is Wallet {

    enum Side {
        BUY,
        SELL
    }
    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount; 
        uint price;
    }

    // maps a ticker to a mapping that maps to buy/sell order in the orderbook
    mapping(bytes32 => mapping(uint => Order[])) orderbook;

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory) {
        return orderbook[ticker][uint(side)];
    }
    
    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public {

    }


}