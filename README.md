# Dividend Timer Smart Contract

A time-locked dividend distribution system built on the Stacks blockchain using Clarity. This contract enables scheduled STX payouts to recipients after configurable time delays, perfect for automated dividend distributions, vesting schedules, or delayed payments.

## Overview

The Dividend Timer contract allows a contract owner to create time-locked dividend schedules that automatically release STX tokens to specified recipients after a predetermined delay. Recipients can claim their dividends once the unlock time is reached, providing a trustless and automated payout system.

## Key Features

- **Time-Locked Distributions**: Create dividend schedules with configurable delays
- **Automated Payouts**: Recipients can claim dividends after unlock time
- **Batch Operations**: Claim multiple dividends in a single transaction
- **Owner Controls**: Fund management and emergency withdrawal capabilities
- **Security**: Protected against double-claiming and unauthorized access
- **Transparency**: Full visibility into schedule status and contract statistics

## Contract Architecture

### Data Structures

- **dividend-schedules**: Maps schedule IDs to dividend information
- **next-schedule-id**: Tracks the next available schedule ID
- **total-locked**: Monitors total locked funds in the contract

### Key Components

- Block-height based timing (approximately 10 minutes per block on Stacks)
- Principal-based recipient management
- Comprehensive error handling with specific error codes
- Emergency controls for contract owner

## Functions

### Public Functions

#### Owner Functions

**`create-dividend-schedule`**
```clarity
(create-dividend-schedule (recipient principal) (amount uint) (delay-blocks uint))
```
Creates a new time-locked dividend schedule.
- `recipient`: The principal who will receive the dividend
- `amount`: Amount of STX to distribute (in micro-STX)
- `delay-blocks`: Number of blocks to wait before allowing claims
- Returns: Schedule ID on success

**`fund-contract`**
```clarity
(fund-contract (amount uint))
```
Adds STX to the contract balance for dividend distributions.

**`emergency-withdraw`**
```clarity
(emergency-withdraw (amount uint))
```
Withdraws unlocked funds from the contract (owner only).

**`cancel-dividend`**
```clarity
(cancel-dividend (schedule-id uint))
```
Cancels an unclaimed dividend before its unlock time.

#### Recipient Functions

**`claim-dividend`**
```clarity
(claim-dividend (schedule-id uint))
```
Claims a dividend after its unlock time. Can be called by anyone.

**`claim-multiple-dividends`**
```clarity
(claim-multiple-dividends (schedule-ids (list 10 uint)))
```
Claims multiple dividends in a single transaction.

### Read-Only Functions

**`get-dividend-schedule`**
```clarity
(get-dividend-schedule (schedule-id uint))
```
Returns complete dividend schedule information.

**`is-dividend-ready`**
```clarity
(is-dividend-ready (schedule-id uint))
```
Checks if a dividend is ready to claim.

**`blocks-until-unlock`**
```clarity
(blocks-until-unlock (schedule-id uint))
```
Returns remaining blocks until dividend unlocks.

**`get-contract-stats`**
```clarity
(get-contract-stats)
```
Returns contract statistics including balances and locked funds.

**`get-recipient-schedule-ids`**
```clarity
(get-recipient-schedule-ids (recipient principal))
```
Returns schedule IDs belonging to a specific recipient.

**`has-pending-dividends`**
```clarity
(has-pending-dividends (recipient principal))
```
Checks if a recipient has any unclaimed dividends.

## Usage Examples

### Creating a Dividend Schedule

```clarity
;; Create a dividend that unlocks after 1 day (144 blocks)
(contract-call? .dividend-timer create-dividend-schedule 
  'SP1ABC...XYZ  ;; recipient
  u1000000       ;; 1 STX (in micro-STX)
  u144           ;; 144 blocks (~24 hours)
)
```

### Claiming a Dividend

```clarity
;; Claim dividend with schedule ID 1
(contract-call? .dividend-timer claim-dividend u1)
```

### Checking Dividend Status

```clarity
;; Check if dividend is ready
(contract-call? .dividend-timer is-dividend-ready u1)

;; Check remaining blocks
(contract-call? .dividend-timer blocks-until-unlock u1)
```

## Time Calculations

The contract uses block heights for timing:
- **1 block** ≈ 10 minutes
- **6 blocks** ≈ 1 hour
- **144 blocks** ≈ 1 day  
- **1008 blocks** ≈ 1 week
- **4320 blocks** ≈ 1 month

## Error Codes

- `u100`: Owner-only function called by non-owner
- `u101`: Schedule not found
- `u102`: Dividend not ready (time-locked) or trying to cancel after unlock
- `u103`: Dividend already claimed
- `u104`: Insufficient funds in contract
- `u105`: Invalid amount (must be greater than 0)
- `u106`: Invalid delay (must be greater than 0)

## Security Considerations

### Access Control
- Only contract owner can create schedules and manage funds
- Anyone can claim dividends after unlock time (enables automated claiming)
- Emergency withdrawal only allows unlocked funds

### Fund Safety
- Funds are locked until unlock time
- Total locked funds tracked to prevent over-withdrawal
- Double-claiming protection via claimed flag

### Time Lock Security
- Uses block height for reliable timing
- Cannot be manipulated by external parties
- Cancellation only allowed before unlock time

## Deployment Guide

1. **Deploy Contract**: Deploy the contract to Stacks blockchain
2. **Fund Contract**: Transfer STX to contract using `fund-contract`
3. **Create Schedules**: Use `create-dividend-schedule` to set up dividends
4. **Monitor**: Use read-only functions to track status
5. **Claim**: Recipients claim dividends after unlock time

## Use Cases

### Corporate Dividends
Set up quarterly dividend distributions with automatic unlock times.

### Employee Vesting
Create vesting schedules for employee token distributions.

### Subscription Payments
Implement delayed payments for subscription services.

### Escrow Services
Hold funds in escrow with time-based release conditions.

### Investment Returns
Distribute investment returns on predetermined schedules.
