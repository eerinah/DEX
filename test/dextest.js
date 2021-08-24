const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require('truffle-assertions');
contract("Dex", accounts => {
    let dex;
    let link;

    before(async function(){
        dex = await Dex.deployed();
        link = await Link.deployed();
    });

    it("Should pass if the BUY orderbook is in descending order", async () => {
        await link.approve(dex.address, 500);
        await dex.createLimitOrder(BUY, web3.utils.fromUtf8("LINK"), 1, 300)
        await dex.createLimitOrder(BUY, web3.utils.fromUtf8("LINK"), 1, 100)
        await dex.createLimitOrder(BUY, web3.utils.fromUtf8("LINK"), 1, 200)
        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), BUY);
        assert.equal(3, orderbook.length, "Missing orders from orderbook")
        for (let i = 0; i < orderbook.length - 1; i++) {
            assert(orderbook[i].price >= orderbook[i+1].price, "Invalid price order")
        }
    });

    it("Should pass if the SELL orderbook is in ascending order", async () => {
        await link.approve(dex.address, 500);
        await dex.createLimitOrder(SELL, web3.utils.fromUtf8("LINK"), 1, 300)
        await dex.createLimitOrder(SELL, web3.utils.fromUtf8("LINK"), 1, 100)
        await dex.createLimitOrder(SELL, web3.utils.fromUtf8("LINK"), 1, 200)
        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), SELL);
        assert.equal(3, orderbook.length, "Missing orders from orderbook")
        for (let i = 0; i < orderbook.length - 1; i++) {
            assert(orderbook[i].price <= orderbook[i+1].price, "Invalid price order")
        }
    });


    it("Should pass if the user has enough Eth deposited to make a BUY order, revert otherwise", async () => {
        
        // creating a limit order with an insufficient amount of funds 
        await truffleAssert.reverts(
            dex.createLimitOrder(BUY, web3.utils.fromUtf8("LINK"), 10, 1)
        );

        // creating a limit order with sufficient amount of funds 
        await dex.depositETH({value: 10});
        await truffleAssert.passes(
            dex.createLimitOrder(BUY, web3.utils.fromUtf8("LINK"), 10, 1)
        );

    });


    it("Should pass if the user has enough token deposited to make a SELL order, revert otherwise", async () => {
        // creating a limit order with insufficient amount of funds 
        await truffleAssert.reverts(
            dex.createLimitOrder(web3.utils.fromUtf8("LINK"), 1, 5,1)
        );
        

        await dex.addtoken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]})
        await link.approve(dex.address, 5)
      
        await dex.deposit(5, web3.utils.fromUtf8("LINK"));

        // creating a limit order with a sufficient amount of funds 
        await truffleAssert.passes(
            dex.createLimitOrder(web3.utils.fromUtf8("LINK"), 1, 5,1)
        );

    });

});