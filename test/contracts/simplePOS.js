const SimplePOS = artifacts.require("SimplePOS.sol")
const SimplePOSToken = artifacts.require("SimplePOSToken.sol")

contract("SimplePOS", accounts => {
    it("should create a contract", async () => {
        let contract = await SimplePOS.new("MyToken", "simMTKN", 100)
        let owner = await contract.owner()
        assert.equal(owner, accounts[0])        
        let posToken = await SimplePOSToken.at(await contract.posToken())
        assert.equal(await posToken.name(), "MyToken")
        assert.equal(await posToken.symbol(), "simMTKN")
        let commission = await contract.commission()
        assert.equal(commission, 100)
    })

    it("should revert if commission is 100%", async () => {
        await assert.revert(SimplePOS.new("MyToken", "simMTKN", 1))        
    })
})
