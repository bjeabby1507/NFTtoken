var FarmBattle = artifacts.require("farmToken");

module.exports = function (deployer) {
  // deployer.deploy(#Nom, )
  deployer.deploy(FarmBattle);
};