var CrowdFundingDoubleUp = artifacts.require("./CrowdFundingDoubleUp.sol");

module.exports = function(deployer) {
  deployer.deploy(CrowdFundingDoubleUp);
};
