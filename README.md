# RealWorldDefi - Tokenized Multi-Asset Management Platform

## Overview

This project implements a decentralized platform for tokenizing and trading real-world assets such as real estate, art, and commodities. Built on blockchain technology, it allows for fractional ownership of high-value assets, increasing liquidity and accessibility for investors. The platform is implemented using Clarity smart contracts on the Stacks blockchain and includes both token management and marketplace functionality.

## Features

- Multi-asset tokenization (real estate, art, commodities, etc.)
- Fractional ownership of high-value assets
- Decentralized marketplace for trading assets
- Smart contract-based asset management
- Approval-based trading system
- Listing management system
- Regulatory compliance tools
- Secure transfer mechanisms

## Smart Contracts Architecture

The platform consists of three main smart contracts:

1. `token.clar`: Manages the tokenization of assets
2. `marketplace.clar`: Handles the buying and selling of tokenized assets
3. `token-trait.clar`: Defines the shared interface for token operations

### Token Contract Functions

#### Public Functions

1. `create-asset (name type total-supply price)`: Create a new tokenized asset
2. `transfer (to asset-id amount)`: Transfer tokens directly
3. `transfer-from (from to asset-id amount)`: Transfer tokens on behalf of another user
4. `approve (spender asset-id amount)`: Approve another address to spend tokens
5. `set-contract-owner (new-owner)`: Update contract ownership

#### Read-Only Functions

1. `is-valid-asset-id (asset-id)`: Validate asset ID
2. `get-asset-details (asset-id)`: Get asset information
3. `get-balance (owner asset-id)`: Check token balance
4. `get-approved-amount (owner spender asset-id)`: Check approved spending amount

### Marketplace Contract Functions

#### Public Functions

1. `create-listing (token asset-id amount price-per-token)`: Create new marketplace listing
2. `cancel-listing (token listing-id)`: Cancel an active listing
3. `purchase-listing (token listing-id amount)`: Purchase tokens from a listing
4. `set-token-contract (new-contract)`: Update token contract reference
5. `set-contract-owner (new-owner)`: Update marketplace contract ownership

#### Read-Only Functions

1. `get-listing-details (listing-id)`: Get information about a listing
2. `is-listing-active (listing-id)`: Check if a listing is active
3. `get-token-contract`: Get current token contract principal

## Setup and Deployment

1. Install the Stacks CLI and development environment
2. Clone the repository:
   ```bash
   git clone https://github.com/fhayvy/RealWorldDefi.git
   cd RealWorldDefi
   ```
3. Deploy the contracts in the following order:
   ```bash
   clarinet contract:deploy token-trait
   clarinet contract:deploy token
   clarinet contract:deploy marketplace
   ```

## Usage Guide

### Asset Management

#### Creating a New Asset
```clarity
(contract-call? .token create-asset 
    "Luxury Apartment 123" 
    "Real Estate" 
    u1000000 
    u100)
```

#### Approving Token Transfers
```clarity
(contract-call? .token approve 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
    u1 
    u1000)
```

#### Transferring Tokens
```clarity
(contract-call? .token transfer 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
    u1 
    u100)
```

### Marketplace Operations

#### Creating a Listing
```clarity
(contract-call? .marketplace create-listing 
    .token 
    u1 
    u100 
    u50)
```

#### Purchasing from a Listing
```clarity
(contract-call? .marketplace purchase-listing 
    .token 
    u1 
    u10)
```

#### Canceling a Listing
```clarity
(contract-call? .marketplace cancel-listing 
    .token 
    u1)
```

## Security Features

- Role-based access control for administrative functions
- Approval-based token transfers
- Balance verification before transfers
- Active listing validation
- Built-in error handling and input validation
- Secure marketplace escrow mechanism

## Error Handling

The contracts include comprehensive error handling with specific error codes:

### Token Contract Errors
- `err-unauthorized (u100)`: Unauthorized operation
- `err-asset-exists (u101)`: Asset already exists
- `err-insufficient-balance (u103)`: Insufficient token balance
- Plus additional validation errors

### Marketplace Contract Errors
- `err-unauthorized (u200)`: Unauthorized operation
- `err-invalid-listing (u201)`: Invalid listing parameters
- `err-listing-not-found (u202)`: Listing doesn't exist
- Plus additional marketplace-specific errors

## Future Enhancements

1. Price oracle integration for real-time asset valuation
2. Advanced trading features (auctions, offers, bulk trades)
3. Enhanced reporting and analytics
4. Multi-signature functionality for high-value transactions
5. Integration with DeFi protocols for lending and borrowing
6. Cross-chain bridge functionality

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/NewFeature`)
3. Commit changes (`git commit -m 'Add NewFeature'`)
4. Push to branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

## License

[Add your chosen license]

## Author

Favour Chiamaka Eze

