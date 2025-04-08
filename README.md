# Decentralized Commercial Lease Management

A blockchain-based system for managing commercial lease agreements using Clarity smart contracts.

## Overview

This project implements a decentralized commercial lease management system on the Stacks blockchain using Clarity smart contracts. It provides a transparent, secure, and efficient way to manage commercial property leases without relying on traditional intermediaries.

## Features

- **Property Verification**: Validate ownership and condition of properties
- **Tenant Verification**: Confirm financial qualifications of potential lessees
- **Lease Agreement Management**: Create, accept, and manage lease terms
- **Maintenance Request Tracking**: Submit, assign, and resolve maintenance issues

## Smart Contracts

### Property Verification Contract

Handles property registration, verification, and condition assessment:

- Register properties with ownership information
- Authorize property inspectors
- Verify property condition and details
- Query property information

### Tenant Verification Contract

Manages tenant financial qualification verification:

- Register as a tenant
- Authorize financial verifiers
- Verify tenant credit scores and income
- Check tenant verification status

### Lease Agreement Contract

Manages the full lifecycle of lease agreements:

- Create lease agreements with terms
- Accept leases (tenant action)
- Record and confirm rent payments
- Terminate or expire leases
- Query lease details

### Maintenance Request Contract

Tracks property maintenance needs:

- Submit maintenance requests
- Assign requests to authorized providers
- Update request status and resolution
- Cancel requests
- Query request details

## Usage

### Property Owner Flow

1. Register property in the property verification contract
2. Wait for property to be verified by an authorized inspector
3. Create lease agreements for verified properties
4. Confirm rent payments from tenants
5. Assign maintenance requests to providers

### Tenant Flow

1. Register as a tenant in the tenant verification contract
2. Get verified by an authorized financial verifier
3. Accept lease agreements
4. Make rent payments
5. Submit maintenance requests

### Administrator Flow

1. Authorize property inspectors
2. Authorize financial verifiers
3. Authorize maintenance providers
4. Oversee the system operation

## Testing

Tests are written using Vitest. Run the tests with:

```bash
npm test
