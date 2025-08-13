# Hardhat(Solidity Smart Contract) Project Helper(Hardhat Ignition).

A Smart Contract(Hardhat Ignition) helper project - demonstrating Solidity smart contract development, deployment and interaction - with only the Hardhat Framework. A free gem-resource for bootstrapping/starting similar projects.

> Default live network(testnet) used on template is **Sepolia**.

## Key Dependencies/Additions.

1. **prettier** and **prettier-plugin-solidity** - for code formatting.
2. **hardhat-contract-sizer** - generate the sizes of available smart contracts, and outputs the result in console whenever the compilation and contract deployments are run. Prolly on some other commands as well.
3. **hardhat-gas-reporter** - for gas calculation and reporting.
4. **solidity-coverage** - for assessing the measure of test coverage on the smart contracts.
5. **solhint** - for Solidity(smart contracts) linting.
6. **dotenv** 😒.
7. **solidity-docgen** - for documentation generation using Natspec comments

## Important commands.

1. `npx hardhat node`

Creates a new hardhat node(local blockchain environment).

2. `npx hardhat compile`

Compiles all the smart contracts in the contracts directory.

3. `npx hardhat ignition deploy ./ignition/modules/<contract-ignition-module>.ts --network <network-name> --deployment-id <desired-deployment-id>`

Deploys your smart contract to the specified network(the network must have been configured in your hardhat config file).

E.g: `npx hardhat ignition deploy ./ignition/modules/Lock.ts --network localhost --deployment-id localhost-deployment`

4. `npx hardhat ignition verify <deployment-id>`

Verifies smart contracts deployed on testnets/mainnets.

E.g: `npx hardhat ignition verify sepolia-deployment`

5. `npx hardhat test`

Runs all tests. It also triggers the gas report output, hence you should be cautious about how much you run tests(with your API key on), to avoid excess cost and/or rate limiting due to too many API requests(see the gas reporter setup inside hardhat config file for more insight).

6. `npx hardhat coverage`

Checks for test coverage. Ensure to add the "solidity coverage import to your hardhat config file(`import solidity-coverage`) - already added on this template.

7. `npm run lint`

For linting Solidity(smart contract) code with solhint(see the `lint` script inside `package.json`).

8. `npx hardhat docgen`

Generates markdown documentations(using Natspec comments that has been added to the contracts) - thanks to OpenZepellin's `solidity-docgen` utility/library

> **The generated docs can be found inside the `docs` folder.**





