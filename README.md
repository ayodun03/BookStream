# BookStream Smart Contract

A monthly subscription service for digital books and audiobooks built on the Stacks blockchain using Clarity.

## Overview

BookStream is a decentralized subscription platform that enables users to access a digital library of books and audiobooks through monthly STX payments. The smart contract handles recurring subscriptions, content access control, and payment processing entirely on-chain.

## Features

- **Monthly Subscriptions**: Pay 5 STX per month for unlimited access
- **Digital Library**: Books and audiobooks with metadata tracking
- **Access Control**: Only active subscribers can access content
- **Automatic Expiration**: Subscriptions automatically expire after 30 days (~4320 blocks)
- **Renewal System**: Easy subscription renewal with single transaction
- **Admin Controls**: Content management and pricing controls
- **Analytics**: Track user access patterns and subscription metrics

## Contract Architecture

### Data Structures

- **Subscriptions**: Track user subscription status, expiration, and payment history
- **Books**: Store book metadata including title, author, genre, and availability
- **User Access**: Log when users access specific books for analytics

### Key Constants

- `monthly-fee`: 5,000,000 microSTX (5 STX)
- Subscription duration: 4,320 blocks (~30 days)
- Contract owner: Deployment address

## Usage

### For Subscribers

#### Subscribe to BookStream
```clarity
(contract-call? .bookstream subscribe)
```
Pays the monthly fee and grants 30 days of access to the library.

#### Renew Subscription
```clarity
(contract-call? .bookstream renew-subscription)
```
Extends your current subscription by another 30 days.

#### Access a Book
```clarity
(contract-call? .bookstream access-book u1)
```
Records access to book with ID 1 (requires active subscription).

#### Cancel Subscription
```clarity
(contract-call? .bookstream cancel-subscription)
```
Deactivates your subscription (no refund for remaining time).

#### Check Subscription Status
```clarity
(contract-call? .bookstream get-subscription 'SP1234567890)
(contract-call? .bookstream is-subscription-active 'SP1234567890)
```

### For Content Managers (Owner Only)

#### Add New Book
```clarity
(contract-call? .bookstream add-book 
    "The Great Gatsby" 
    "F. Scott Fitzgerald" 
    "Fiction" 
    false)  ;; false = book, true = audiobook
```

#### Manage Book Availability
```clarity
;; Disable a book
(contract-call? .bookstream set-book-availability u1 false)

;; Enable a book
(contract-call? .bookstream set-book-availability u1 true)
```

#### Update Pricing
```clarity
(contract-call? .bookstream set-monthly-fee u3000000)  ;; 3 STX
```

#### Withdraw Funds
```clarity
(contract-call? .bookstream withdraw-funds u1000000)  ;; 1 STX
```

#### Emergency Controls
```clarity
;; Pause new subscriptions
(contract-call? .bookstream pause-contract)

;; Resume normal operation
(contract-call? .bookstream unpause-contract)
```

## Read-Only Functions

### User Information
- `get-subscription(user)`: Get complete subscription details
- `is-subscription-active(user)`: Check if user has active subscription
- `can-access-book(user, book-id)`: Verify book access permissions

### Content Information
- `get-book(book-id)`: Get book details and metadata
- `get-monthly-fee()`: Current subscription price
- `get-total-subscribers()`: Number of active subscribers

### Contract Statistics
- `get-contract-stats()`: Overall platform metrics
- `is-contract-paused()`: Check if contract is paused

## Deployment

1. **Prerequisites**
   - Stacks wallet with STX for deployment
   - Clarinet for local testing
   - Access to Stacks testnet/mainnet

2. **Local Testing**
   ```bash
   clarinet check
   clarinet test
   ```

3. **Deploy to Testnet**
   ```bash
   clarinet deploy --testnet
   ```

4. **Deploy to Mainnet**
   ```bash
   clarinet deploy --mainnet
   ```

## Economic Model

- **Monthly Fee**: 5 STX per user per month
- **Revenue Share**: All payments go to contract owner
- **No Token**: Pure STX-based payment system
- **Subscription Model**: Recurring monthly payments required for access

## Security Features

- **Access Control**: Owner-only admin functions
- **Input Validation**: All parameters validated before execution
- **Error Handling**: Comprehensive error codes and messages
- **Fund Security**: Contract balance tracking and withdrawal controls
- **Emergency Pause**: Ability to halt operations if needed

## Error Codes

- `u100`: Owner-only function called by non-owner
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Insufficient funds for operation
- `u104`: Subscription expired
- `u105`: Unauthorized access attempt

## Integration Examples

### Frontend Integration (JavaScript)

```javascript
import { openContractCall } from '@stacks/connect';

// Subscribe to BookStream
const subscribe = async () => {
  await openContractCall({
    contractAddress: 'SP...',
    contractName: 'bookstream',
    functionName: 'subscribe',
    functionArgs: [],
    network: 'testnet'
  });
};

// Check subscription status
const checkSubscription = async (userAddress) => {
  const result = await callReadOnlyFunction({
    contractAddress: 'SP...',
    contractName: 'bookstream',
    functionName: 'is-subscription-active',
    functionArgs: [principalCV(userAddress)],
    network: 'testnet'
  });
  return result;
};
```

### Backend Integration (Node.js)

```javascript
const { StacksTestnet } = require('@stacks/network');
const { callReadOnlyFunction, principalCV } = require('@stacks/transactions');

const network = new StacksTestnet();

const getBookDetails = async (bookId) => {
  const result = await callReadOnlyFunction({
    contractAddress: 'SP...',
    contractName: 'bookstream',
    functionName: 'get-book',
    functionArgs: [uintCV(bookId)],
    network
  });
  return result;
};
```

## Roadmap

- **V1**: Basic subscription and book access ✅
- **V2**: Multi-tier pricing plans
- **V3**: NFT-based book ownership
- **V4**: Creator revenue sharing
- **V5**: Cross-chain compatibility

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Submit a pull request with detailed description

## License

MIT License - see LICENSE file for details

## Audit Status

⚠️ **This contract has not been audited**. Use at your own risk in production environments. Consider professional smart contract audits before mainnet deployment with significant funds.