import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "solidity-coverage";
import "solidity-docgen";

import dotenv from "dotenv";
dotenv.config();

const sepoliaRPCURL = (process.env.RPC_URL as string) || "******"; // specifying "or" values like so can be helpful.
const privateKey = process.env.PRIVATE_KEY as string;
const etherscanAPIKey = process.env.ETHERSCAN_API_KEY;
const coinMarketCapAPIKey = process.env.COINMARKETCAP_API_KEY;

// console.log(privateKey);

const config: HardhatUserConfig = {
    // solidity: '0.8.8', // single version mode
    solidity: {
        compilers: [
            { version: "0.8.28" },
            // { version: '0.8.8' },
            // { version: '0.6.6' }
        ],
    },
    defaultNetwork: "hardhat", // we actually don't need to set this - it'll be hardhat by default
    networks: {
        sepolia: {
            url: sepoliaRPCURL,
            accounts: [privateKey],
            chainId: 11155111,
        },
        localhost: {
            url: "http://localhost:8545", // or "http://127.0.0.1:8545/"
            // no need for an account - hardhat will select for us from the node that will be spurned up.
            chainId: 31337,
        },
    },
    etherscan: {
        apiKey: {
            sepolia: etherscanAPIKey!,
            // mainnet: 'YOUR_ETHERSCAN_API_KEY',
            // optimisticEthereum: 'YOUR_OPTIMISTIC_ETHERSCAN_API_KEY',
            // arbitrumOne: 'YOUR_ARBISCAN_API_KEY',
        },
    },
    sourcify: {
        enabled: true,
    },
    contractSizer: {
        runOnCompile: true,
        outputFile: "contract-sizes.txt",
        unit: "kB",
    },
    gasReporter: {
        enabled: true,
        // outputFile: 'gas-report.txt', // if we don't add this, the report will be outputed into the console.
        // noColors: true, // the reason for this is because the colors can get messed up if we output it into a file. You can use this if you want your report in the console.
        currency: "USD",
        // coinmarketcap: coinMarketCapAPIKey, // we need this to work with the currency part. it makes an API call to coinmarketcap anytime we run the gas reporter(i.e. anytime we run the tests). Hence it might be important to comment this out sometimes so we save the api calls.
        // token: 'ETH', // this specifies the token with you you want to get the gas report in relation to. Prices might show zeros it's because the USD values in relation to a specified token is very small compared to the allowed decimal places.
        token: "MATIC",
    },
    docgen: {
        // root: process.cwd(),
        // sourcesDir: "contracts",
        outputDir: "./docs",
        pages: "single",
        exclude: [],
        theme: "markdown",
        collapseNewlines: true,
        pageExtension: ".md",
    },
};

export default config;
