const { ethers, network, upgrades } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
require("dotenv").config();

async function main() {
  console.log("start");
  const kycFactory = await ethers.getContractFactory("KYC");
  const kycProxy = await upgrades.deployProxy(kycFactory, [3010], {
    initializer: "initialize",
  });
  await kycProxy.waitForDeployment();
  console.log("deployed");
  const networkConfig = {
    [network.name]: {
      etherscanApiKey: process.env.ETHERSCAN_API_KEY,
    },
  };

  if (
    networkConfig[network.name] &&
    networkConfig[network.name].etherscanApiKey
  ) {
    console.log("Veryfing...");

    await verify(
      await kycProxy.getAddress(),
      [],
      networkConfig[network.name].etherscanApiKey
    );
  }
}
main();
// module.exports = async () => {

// };

module.exports.tags = ["all", "kyc", "main"];
