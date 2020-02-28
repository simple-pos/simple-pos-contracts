const SimplePOS = artifacts.require("SimplePOS")
const SimplePOSToken = artifacts.require("SimplePOSToken")
const MockUniswapExchange = artifacts.require("MockUniswapExchange")

contract("SimplePOS", accounts => {
    it("should create a contract", async () => {
        let exchange = await MockUniswapExchange.new()
        let contract = await SimplePOS.new(exchange.address, "MyToken", "simMTKN", 100)
        let owner = await contract.owner()
        assert.equal(owner, accounts[0])
        let posToken = await SimplePOSToken.at(await contract.posToken())
        assert.equal(await posToken.name(), "MyToken")
        assert.equal(await posToken.symbol(), "simMTKN")
        let commission = await contract.commission()
        assert.equal(commission, 100)
        let exchangeAddress = await contract.getExchangeAddress()
        assert.equal(exchangeAddress, exchange.address)
        let liquidityTokenAddress = await contract.getLiquidityTokenAddress()
        assert.equal(liquidityTokenAddress, await exchange.tokenAddress())
    })

    it("should revert if commission is 100%", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1))
    })
})
