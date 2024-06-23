const networkConfig = {
  31337: {
    name: "localhost",
    callbackGasLimit: "500000", // 500,000 gas
  },
  11155111: {
    name: "sepolia",
    callbackGasLimit: "500000", // 500,000 gas
  },
};

const developmentChains = ["sepolia", "localhost"];

module.exports = {
  networkConfig,
  developmentChains,
};
