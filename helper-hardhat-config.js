const networkConfig = {
  31337: {
    name: "hardhat",
    callbackGasLimit: "500000", // 500,000 gas
  },
  11155111: {
    name: "sepolia",
    callbackGasLimit: "500000", // 500,000 gas
  },
};

const developmentChains = ["sepolia", "hardhat"];

module.exports = {
  networkConfig,
  developmentChains,
};
