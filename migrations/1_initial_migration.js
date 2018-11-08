var Migrations = artifacts.require("./Migrations.sol");
var Issuance = artifacts.require("./Issuance.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Issuance);
};
