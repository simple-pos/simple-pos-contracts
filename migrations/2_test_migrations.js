const MockUniswapExchange = artifacts.require("MockUniswapExchange")
const SimplePOS = artifacts.require("SimplePOS")

module.exports = function(deployer) {
    deployer.deploy(MockUniswapExchange).then(function() {    
        return deployer.deploy(SimplePOS, MockUniswapExchange.address, "MyToken", "simMTKN", 1, 500, 5000, { value: 1000000000000000000 });
    })
};
