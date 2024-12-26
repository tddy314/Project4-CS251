require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-ethers")
require("dotenv").config();

module.exports = {
  solidity: "0.8.17",
  networks: {
    bscTestnet: {
      url : process.env.URL,
      accounts:  [process.env.PRIVATE_KEY]
    }
  }
};
