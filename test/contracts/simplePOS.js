const SimplePOS = artifacts.require("SimplePOS")
const SimplePOSToken = artifacts.require("SimplePOSToken")
const MockUniswapExchange = artifacts.require("MockUniswapExchange")

const { toEth, fromEth } = require('../utils/testUtils')
const maxUint = "115792089237316195423570985008687907853269984665640564039457584007913129639935" // 2^256 - 1

contract("SimplePOS", accounts => {
    it("should create a contract", async () => {
        let exchange = await MockUniswapExchange.new()
        let initialEthValue = toEth(0.1)
        let contract = await SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 100, 5000, { value: initialEthValue })
        // owner should be the creator        
        assert.equal(await contract.owner(), accounts[0])
        // check SPOS token params
        let sposToken = await SimplePOSToken.at(await contract.sposToken())
        assert.equal(await sposToken.name(), "MyToken")
        assert.equal(await sposToken.symbol(), "simMTKN")
        // check commission
        assert.equal(await contract.commission(), 100)
        // check curve coefficient
        assert.equal(await contract.curveCoefficient(), 5000)
        // check exchange        
        assert.equal(await contract.getExchangeAddress(), exchange.address)
        // check that bonus token is the same as exchange token
        assert.equal(await contract.getBonusTokenAddress(), await exchange.tokenAddress())
        // check that SPOS token is minted in the right proportion (MockUniswapExchange._ethToTokenSwapRate == 1)
        // and transfered to the creator
        let totalSupply = await sposToken.totalSupply()
        assert.equal(fromEth(totalSupply), fromEth(initialEthValue))
        let creatorBalance = await sposToken.balanceOf(accounts[0])
        assert.equal(fromEth(creatorBalance), fromEth(initialEthValue))
        // check that contract Eth balance is zero
        assert.equal(await web3.eth.getBalance(contract.address), 0)
    })

    it("should revert constructor if commission is 100%", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 10000, 5000, { value: toEth(0.1) }),
                            "Commission should be less than 100%")
    })

    it("should revert constructor if value is not transfered", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 100, 5000),
                            "ETH is required to form bonus tokens pool")
    })

    it("should revert constructor if initial ratio is zero", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 0, 100, 5000, { value: toEth(0.1) }),
                            "Initial ratio should be positive")
    })

    it("should revert constructor if curve coefficient is 100%", async () => {
        let exchange = await MockUniswapExchange.new()
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 100, 10000, { value: toEth(0.1) }),
                            "Curve coefficient should be less than 100%")
    })

    it("should revert constructor if initialMintedPOSTokens is overflowed", async () => {
        let exchange = await MockUniswapExchange.new()
        let oneWei = toEth(fromEth("1"))
        let contract = await SimplePOS.new(exchange.address, "MyToken", "simMTKN", maxUint, 100, 5000, { value: oneWei })
        let sposToken = await SimplePOSToken.at(await contract.sposToken())
        let totalSupply = await sposToken.totalSupply()
        assert.equal(fromEth(totalSupply), fromEth(maxUint))
        // should overflow
        await exchange.setEthToTokenSwapRate(2)
        await assert.revert(SimplePOS.new(exchange.address, "MyToken", "simMTKN", maxUint, 100, 5000, { value: oneWei }),
                            "SafeMath: multiplication overflow.")
    })
})
