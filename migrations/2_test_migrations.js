const MockUniswapExchange = artifacts.require("MockUniswapExchange")
const SimplePOS = artifacts.require("SimplePOS")
const SimplePOSFactory = artifacts.require("SimplePOSFactory")

module.exports = function (deployer) {
  deployer.deploy(MockUniswapExchange).then(function () {
    return deployer.deploy(SimplePOSFactory)
  })
}
