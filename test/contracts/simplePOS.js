const SimplePOS = artifacts.require("SimplePOS")
const SimplePOSToken = artifacts.require("SimplePOSToken")
const MockUniswapExchange = artifacts.require("MockUniswapExchange")

const { toEth } = require('../utils/testUtils')

contract("SimplePOS", accounts => {
    it("should create a contract", async () => {
        let exchange = await MockUniswapExchange.new()
        let contract = await SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 100, { value: toEth(0.1) })
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

    it("should revert constructor if commission is 100%", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 1),
                            "Commission should not be 100%")
    })

    it("should revert constructor if value is not transfered", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 100),
                            "ETH is required to provide initial liquidity in _exchange token for SimplePOS.")
    })

    it("should revert constructor if initial ratio is zero", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 0, 100, { value: toEth(0.1) }),
                            "Initial ratio should be positive.")
    })
})
