const SimplePOS = artifacts.require("SimplePOS.sol")

contract("SimplePOS", accounts => {
    it("should create a contract", async () => {
        let contract = await SimplePOS.new()
        let owner = await contract.owner()        
        assert.equal(owner, accounts[0])
    })
})
