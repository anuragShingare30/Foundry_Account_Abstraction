## Account Abstraction

- **Account Abstraction (AA) is a concept in Ethereum that` enhances user experience` by allowing smart contracts to act as user accounts(EOAs)**
- This removes the traditional process of EOAs for initiating transactions!!!

- **Account Abstraction** modifies the traditional Ethereum account model by `introducing smart contract wallets that can act like EOAs`
- **AA** improves


## What is ERC-4337?


**`ERC-4337` is a specification that aims to use an `entry point contract` to achieve account abstraction `without changing the consensus layer protocol` of Ethereum.**
- Instead of modifying the logic of the consensus layer itself, ERC-4337 replicates the functionality of the transaction mempool in a higher-level system

- ERC-4337 also introduces `paymaster mechanism` -> Other users can pay the gas fees for the transaction in ERC-20 tokens



### There are several main components to ERC-4337 :-

1. **`UserOperation`**:
   - This are `transaction objects` that are used to execute transactions with contract accounts. 
   - UserOp struct contains  ->> sender address, nonce, bytes functionData, signature...
   - `sender` -> address of the smart contract account
   - `functionData` -> Data that's passed to the sender for execution (function selector!!!)


2. **`UserOperation mempool`**: 
   - UserOperations will be sent to the UserOperation mempool
   - Bundlers listen to the UserOperation mempool and `bundle multiple UserOperations` together into a "classic" transaction.

3. **`Bundlers`**:
   - These are **specialized nodes** that `collect UserOperations` from multiple users and `package them into a single Ethereum block for efficiency`
   - A bundler is the core infrastructure component that allows `account abstraction to work on any EVM network `
   - This work with a new mempool of UserOperations and get the transaction included on-chain.
   - This package UserOperations from a mempool and `send them to the EntryPoint` contract on-chain

4. **`Paymasters contracts`**:
   - This are smart contract accounts that can `pays the gas fees for Account Contracts`
   - Users can also pay in `ERC-20 tokens` instead of ETH
   - `Paymasters` are included -> because the wallet owner needs to find a way to get some ETH before interaction with DApps on-chain
   - With paymasters, ERC-4337 allows abstracting gas payments altogether, meaning `​​someone other than the wallet owner can pay for the gas instead.`
   - This makes user experience better!!!


5. **`Entry point contract`**:
   - This contract `verifies and executes` the bundles of UserOperations sent to it from bundlers!!!
   - The use of a single EntryPoint contract simplifies the logic used by smart contract wallets
   - Bundlers will send many userOps to entrypoint contract
   - This will `verify each userOps with contract accounts`
   - After verification -> EntryPoint contract will asks contract account to execute the specific function

6. **`Smart contract Account`**:
   - An smart contract wallet of user
   - This contract account should consist two functions -> `validateUserOps` and `executeUserOps`
   - one to verify signatures, and another to process transactions.




### Account Abstraction Flow!!!


1. **AA user -> Bundlers**
   - AA user will signed userOp (where sender will be contract account)
   - `Bundlers` will collect many userOps
   - Verifies the userOps ->  Sign them in a TNX ->  Send it off to the entryPoint contract

2. **Bundlers will simulate each userOps**:
   - Bundlers after collecting all userOps -> Send that to the entrypoint contract for `simulating and verifying` each userOps with contract account and paymasters
   - `EntryPoint contract` will verifies each userOps on-chain with contract account
  
3. **Bundlers will submit TNX to entry point contract**:
   - `Entrypoint` will checks for verified userOps with contract account
   - Paymasters will verify the userOps
   - After `verification` -> Contract account `executes the function and perform the state changes`!!! 









## Sources


1. Account abstraction github repo!!!
   - https://github.com/eth-infinitism/account-abstraction
   - https://github.com/stackup-wallet

2. Blogs and articles for AA
   - https://www.erc4337.io/docs
   - https://www.cyfrin.io/blog/what-is-blockchain-account-abstraction-a-5-minute-guide
   - https://eips.ethereum.org/EIPS/eip-4337 
   - https://ethereum.org/en/roadmap/account-abstraction/