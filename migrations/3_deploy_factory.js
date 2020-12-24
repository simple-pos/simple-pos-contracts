const SimplePOSFactory = artifacts.require("SimplePOSFactory")

module.exports = function (deployer) {
  deployer.deploy(SimplePOSFactory)
}
