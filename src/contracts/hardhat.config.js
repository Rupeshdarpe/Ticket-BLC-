require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    ganache: {
      url: "http://127.0.0.1:7545",
      accounts: [
        `0xe7dfdff8cfe972fe27c5a39a80d7b295bc99e7f58129b882f97d8cf15453fc56`,
      ],
    }
  }
};
