const SimplePOS = artifacts.require("SimplePOS")
const SimplePOSFactory = artifacts.require("SimplePOSFactory")
const SimplePOSToken = artifacts.require("SimplePOSToken")
const MockUniswapExchange = artifacts.require("MockUniswapExchange")
const MockStableCoin = artifacts.require("MockStableCoin")
const Subscription = artifacts.require("Subscription")

const { toEth, fromEth, sign } = require("../utils/testUtils")
const maxUint =
  "115792089237316195423570985008687907853269984665640564039457584007913129639935" // 2^256 - 1

contract("SimplePOSFactory", (accounts) => {
  /***************************************
   ************* createPOS *************
   ***************************************/
  it("should deploy a SimplePOS contract", async () => {
    let exchange = await MockUniswapExchange.new()
    let initialEthValue = toEth(0.1)
    let factory = await SimplePOSFactory.deployed()
    let creationTX = await factory.createPOS(
      exchange.address,
      "MyToken",
      "simMTKN",
      1,
      100,
      5000,
      { value: initialEthValue }
    )
    let sposAddress = creationTX.logs[0].args.spos
    let spos = await SimplePOS.at(sposAddress)

    // owner should be the creator
    assert.equal(await spos.owner(), accounts[0])

    // check SPOS token params
    let sposToken = await SimplePOSToken.at(await spos.sposToken())
    assert.equal(await sposToken.name(), "MyToken")
    assert.equal(await sposToken.symbol(), "simMTKN")
    // check commission
    assert.equal(await spos.commission(), 100)
    // check curve coefficient
    assert.equal(await spos.curveCoefficient(), 5000)
    // check exchange
    assert.equal(await spos.exchange(), exchange.address)
    // check that bonus token is the same as exchange token
    assert.equal(
      await spos.getBonusTokenAddress(),
      await exchange.tokenAddress()
    )
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
    assert.equal(
      fromEth(await mockBonusToken.balanceOf(spos.address)),
      fromEth(totalSupply)
    )
    // check that contract Eth balance is zero
    assert.equal(await web3.eth.getBalance(spos.address), 0)
    // check that the proper subscription is created
    let subscription = await Subscription.at(await spos.subscription())
    assert.equal(await subscription.author(), spos.address)
  })
})
