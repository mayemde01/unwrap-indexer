# Unwrap Indexer

A decentralized asset tracking and verification protocol built on the Stacks blockchain. The Unwrap Indexer provides a robust infrastructure for creating transparent, immutable, and verifiable records of asset ownership, provenance, and lifecycle management.

## Overview

Asset Tracking Vault enables users to:
- Register assets with detailed metadata
- Transfer ownership securely
- Track complete asset provenance
- Add third-party attestations
- Manage asset status (active/inactive)
- View complete ownership history

The system is particularly valuable for:
- Insurance claims processing
- Proof of ownership verification
- Asset management
- Fraud prevention
- Supply chain tracking

## Architecture

The system is built around a central asset vault contract that manages all asset-related operations and maintains several interconnected data structures.

```mermaid
graph TD
    A[Asset Registration] --> B[Asset Vault Contract]
    B --> C[Asset Data Structure]
    B --> D[History Tracking]
    B --> E[Attestations]
    B --> F[Owner Registry]
    
    C --> G[Metadata]
    C --> H[Ownership]
    C --> I[Status]
    
    D --> J[Transfer History]
    D --> K[Status Changes]
    
    E --> L[Third-party Verification]
    E --> M[Supporting Documents]
    
    F --> N[Owner Assets]
    F --> O[Access Control]
```

## Contract Documentation

### Asset Vault Contract

The main contract (`asset-vault.clar`) handles all asset-related operations and data storage.

#### Key Data Structures
- `assets`: Stores core asset information
- `asset-history`: Tracks ownership transfers
- `asset-attestations`: Stores third-party verifications
- `principal-assets`: Maps owners to their assets

#### Access Control
- Asset modifications restricted to current owner
- Attestations can be added by any principal
- Transfers require current owner authorization

## Getting Started

### Prerequisites
- Clarinet
- Stacks wallet for deployment

### Installation
1. Clone the repository
2. Install dependencies with Clarinet
3. Deploy contract to desired network

### Basic Usage

```clarity
;; Register a new asset
(contract-call? .asset-vault register-asset 
    "Vintage Watch" 
    u5000 
    u1234567 
    "Excellent" 
    (some "ipfs://Qm...</"))

;; Transfer asset ownership
(contract-call? .asset-vault transfer-asset 
    u1 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
    (some "Sale completed"))
```

## Function Reference

### Public Functions

#### register-asset
```clarity
(define-public (register-asset 
    (description (string-ascii 256))
    (value uint)
    (date-acquired uint)
    (condition (string-ascii 64))
    (metadata-uri (optional (string-utf8 256))))
```

#### transfer-asset
```clarity
(define-public (transfer-asset
    (asset-id uint)
    (new-owner principal)
    (notes (optional (string-ascii 256))))
```

#### add-attestation
```clarity
(define-public (add-attestation
    (asset-id uint)
    (attestation-type (string-ascii 64))
    (details (string-utf8 256))
    (uri (optional (string-utf8 256))))
```

### Read-Only Functions

#### get-asset
```clarity
(define-read-only (get-asset (asset-id uint)))
```

#### get-assets-by-owner
```clarity
(define-read-only (get-assets-by-owner (owner principal)))
```

## Development

### Testing
Run the test suite using Clarinet:
```bash
clarinet test
```

### Local Development
1. Start Clarinet console:
```bash
clarinet console
```
2. Deploy contract:
```bash
(contract-call? .asset-vault ...)
```

## Security Considerations

### Limitations
- Asset metadata size limited to 256 characters
- Maximum 100 assets per principal
- No built-in encryption for sensitive metadata

### Best Practices
- Always verify asset ownership before transfers
- Use secure URIs for sensitive metadata storage
- Keep detailed transfer notes for audit purposes
- Regularly monitor asset status and attestations
- Validate all inputs before registration

### Error Handling
The contract includes comprehensive error codes:
- `ERR-NOT-AUTHORIZED (u100)`
- `ERR-ASSET-NOT-FOUND (u101)`
- `ERR-INVALID-DETAILS (u102)`
- `ERR-ALREADY-EXISTS (u103)`
- `ERR-UNAUTHORIZED-TRANSFER (u104)`
- `ERR-INVALID-RECEIVER (u105)`
- `ERR-UNAUTHORIZED-ATTESTATION (u106)`