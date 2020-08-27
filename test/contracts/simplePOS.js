const SimplePOS = artifacts.require("SimplePOS")
const SimplePOSToken = artifacts.require("SimplePOSToken")
const MockUniswapExchange = artifacts.require("MockUniswapExchange")
const MockStableCoin = artifacts.require("MockStableCoin")

const { toEth, fromEth } = require('../utils/testUtils')
const maxUint = "115792089237316195423570985008687907853269984665640564039457584007913129639935" // 2^256 - 1

contract("SimplePOS", accounts => {
    /***************************************
     ************* CONSTRUCTUR *************
     ***************************************/

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
        // check that the contract creator gets minted SPOS tokens
        let creatorBalance = await sposToken.balanceOf(accounts[0])
        assert.equal(fromEth(creatorBalance), fromEth(initialEthValue))
        // check that SimplePOS contract controls bonus pool 
        // (1 to 1 with sposToken.totalSupply as contract.initialRation == 1)      
        let mockBonusToken = await MockStableCoin.at(await exchange.tokenAddress())
        assert.equal(fromEth(await mockBonusToken.balanceOf(contract.address)), fromEth(totalSupply))
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

    /***************************************
     ************ RECEIVE ETHER ************
     ***************************************/

    it("should receive payements and mint bonus tokens accordingly", async () => {
        let exchange = await MockUniswapExchange.new()
        let mockBonusToken = await MockStableCoin.at(await exchange.tokenAddress())

        let initialEthValue = toEth(1)
        // fee: 5%; curve_coefficient: 50%
        let contract = await SimplePOS.new(exchange.address, "MyToken", "simMTKN", 1, 500, 5000, { value: initialEthValue }) // why at this step only one additional contract is created in the Ganache?

        // check that SPOS token is minted in the right proportion (MockUniswapExchange._ethToTokenSwapRate == 1)
        // and transfered to the creator
        let sposToken = await SimplePOSToken.at(await contract.sposToken())
        let totalSupply = await sposToken.totalSupply()
        assert.equal(fromEth(totalSupply), fromEth(initialEthValue)) // 1
        let creatorBalance = await sposToken.balanceOf(accounts[0])
        assert.equal(fromEth(creatorBalance), fromEth(initialEthValue))

        // Check values against test vectors
        let testVector = [
            { 'account': accounts[1], 'eth': 1, 'idp': 1.05, 'spos': 1.025 },
            { 'account': accounts[2], 'eth': 5, 'idp': 1.3, 'spos': 1.147124865761983793 },
            { 'account': accounts[3], 'eth': 10, 'idp': 1.8, 'spos': 1.367807977409106953 },
            { 'account': accounts[4], 'eth': 50, 'idp': 4.3, 'spos': 2.317805304354434227 }
        ]
        for (var i in testVector) {
            let v = testVector[i]
            await contract.sendTransaction({from: v.account, value: toEth(v.eth)})
            assert.equal(fromEth(await mockBonusToken.balanceOf(contract.address)), v.idp)
            assert.equal(fromEth(await sposToken.totalSupply()), v.spos)    
        }
        assert.equal(fromEth(await sposToken.balanceOf(accounts[4])), 0.949997326945327274)
    })
})
