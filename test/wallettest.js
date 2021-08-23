const Dex = artifact.require("Dex");
const Link = artifact.require("Link");
const truffleAssert = require('truffle-assertions');
contract("Dex", accounts => {
    it("Should only be possible for Owner to add tokens", async () => {
        await deployer.deploy(Link);
        let dex = await Dex.deployed();
        let link =  await Link.deployed();
        wallet.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]});
    })
})