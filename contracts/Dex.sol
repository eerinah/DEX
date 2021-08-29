pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./Wallet.sol";

contract Dex is Wallet {

    using SafeMath for uint256;
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
        uint filled;
    }
    uint public nextOrderID = 0;

    // maps a ticker to a mapping to buy/sell orders in the orderbook
    mapping(bytes32 => mapping(uint => Order[])) orderbook;

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory) {
        return orderbook[ticker][uint(side)];
    }
    
    function createLimitOrder(Side _side, bytes32 _ticker, uint _amount, uint _price) public {

        if (_side == Side.BUY) {
            require(balances[msg.sender]["ETH"] >= _amount.mul(_price), "not enough Ether to place buy order");

            // create new buy order
            Order[] storage orders = orderbook[_ticker][0];
            orders.push(
                Order(nextOrderID, msg.sender, _side, _ticker, _amount, _price, 0)
            );
            nextOrderID++;

            // sort buy orderbook in descending order
            uint i = orders.length > 0 ? orders.length - 1 : 0;
            while (i > 0) {
                if (orders[i].price >= orders[i - 1].price) {
                    Order memory temp = orders[i];
                    orders[i] = orders[i - 1];
                    orders[i - 1] = temp;
                }
                i--;
            }
        }

        if (_side == Side.SELL) {
            require(balances[msg.sender][_ticker] >= _amount, "not enough tokens to place sell order");

            // create new sell order
            Order[] storage orders = orderbook[_ticker][1];
            orders.push(
                Order(nextOrderID, msg.sender, _side, _ticker, _amount, _price, 0)
            );
            nextOrderID++;

            // sort sell orderbook in ascending order
            uint i = orders.length > 0 ? orders.length - 1 : 0;
            while (i > 0) {
                if (orders[i].price <= orders[i - 1].price) {
                    Order memory temp = orders[i];
                    orders[i] = orders[i - 1];
                    orders[i - 1] = temp;
                }
                i--;
            }
        }
    }

    function createMarketOrder(Side _side, bytes32 _ticker, uint _amount) public {
        uint orderBookSide;
        if (_side == Side.BUY) {
            orderBookSide = 1;
        } else {
            require(balances[msg.sender][_ticker] >= _amount, "Insufficient funds to execute transaction");
            orderBookSide = 0;
        }
        Order[] storage orders = orderbook[_ticker][orderBookSide];
        uint totalFilled = 0;
        for (uint i = 0; i < orders.length && totalFilled < _amount; i++) {

            // How much can we fill from orders[i] ? 
            uint amountLeft = _amount.sub(totalFilled);
            uint liquidityLeft = orders[i].amount.sub(orders[i].filled);
            uint toTransfer = 0;

            // if the current order has less or equal liquidity than the amount needed to fill the market order
            if (liquidityLeft <= amountLeft) {  
                toTransfer = liquidityLeft; // fills the market order partially  

            } else { // the current order has more liquidity than the amount needed to fill the market order
                toTransfer = amountLeft;    // fills the market order completely
            }

            orders[i].filled = orders[i].filled.add(toTransfer);
            totalFilled = totalFilled.add(toTransfer);

            // Execute the trade and shift balances between the buyer and seller 
            uint price = toTransfer.mul(orders[i].price);
            if (_side == Side.BUY) {
                // must have enough ETH to execute trade 
                require(balances[msg.sender]["ETH"] > price);

                // transfer ETH from buyer to seller 
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(price);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(price);

                // transfer token from seller to buyer
                balances[orders[i].trader][_ticker] = balances[orders[i].trader][_ticker].sub(toTransfer);
                balances[msg.sender][_ticker] = balances[msg.sender][_ticker].add(toTransfer);
                
            } else { // _side == Side.SELL
                // must have enough tokens to execute trade 
                require(balances[msg.sender][_ticker] > price);

                // transfer token from seller to buyer
                balances[msg.sender][_ticker] = balances[msg.sender][_ticker].sub(price);
                balances[orders[i].trader][_ticker] = balances[orders[i].trader][_ticker].add(price);

                // transfer ETH from buyer to seloer
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(toTransfer);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(toTransfer);
            }
        }
        // loop through the orderbook and remove the 100% filled orders
        // filled orders settle at the top of the orderbook
        while (orders.length > 0 && orders[0].filled == orders[0].amount) {
            // remove the top element in the orders array by overwriting it with the next element in the array
            for (uint i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
    }

}
