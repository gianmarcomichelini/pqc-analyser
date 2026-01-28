# ML-KEM and ECDH Simulation

This toolkit demonstrates both post-quantum and classical key exchange mechanisms, providing a complete workflow for establishing shared secrets between two parties over insecure channels.

## Prerequisites

Before using this toolkit, ensure you have:

1. OpenSSL with OQS Provider installed and configured
2. Environment variables properly set
3. Generated keys using `./mlkem/generate_mlkem_keys.sh`

## ML-KEM Key Encapsulation Simulation

ML-KEM (Module-Lattice-Based Key Encapsulation Mechanism) represents the post-quantum cryptographic approach for secure key exchange.

### Usage
```bash
chmod +x kem_simulation.sh
./kem_simulation.sh
```

### Example Output
```
Testing ml-kem-512...
1. Encapsulating (Sender)... [OK]
2. Decapsulating (Receiver)... [OK]
3. Verifying Shared Secrets... [SUCCESS]
   Shared Secrets Match!

Visual Proof (First 32 bytes):
Sender:   a1b2c3d4...
Receiver: a1b2c3d4...
```

## KEM Performance Benchmarking

The `benchmark_kem.sh` script measures the speed of Key Encapsulation (Post-Quantum) versus Key Agreement (Classical).

### Usage
```bash
chmod +x benchmark_kem.sh
./benchmark_kem.sh <type> <algorithm>
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| type | `pq` (Post-Quantum) or `classical` (Standard) |
| algorithm | **PQ:** `ml-kem-512`, `ml-kem-768`, `ml-kem-1024` <br> **Classical:** `ecdh` (uses NIST P-256) |

### Examples

Benchmark ML-KEM-768 (Recommended Standard):
```bash
./benchmark_kem.sh pq ml-kem-768
```

Benchmark ML-KEM-1024 (High Security):
```bash
./benchmark_kem.sh pq ml-kem-1024
```

Benchmark Classical ECDH (P-256):
```bash
./benchmark_kem.sh classical ecdh
```

### Output Interpretation

The script runs 100 iterations and reports:

- **Encapsulation (Sender):** Time required to encrypt the shared secret
- **Decapsulation (Receiver):** Time required to decrypt the shared secret

## Classical ECDH Key Agreement Simulation

This script simulates traditional Elliptic Curve Diffie-Hellman (ECDH) key exchange between two parties (Alice and Bob). Unlike ML-KEM, ECDH represents the classical cryptographic approach that is vulnerable to quantum attacks but widely used today.

### Purpose

The ECDH simulation demonstrates:
- How two parties can establish a shared secret without transmitting it
- The classical key agreement process using elliptic curve cryptography
- Performance baseline for comparison with post-quantum algorithms

### Usage
```bash
chmod +x ecdh_simulation.sh
./ecdh_simulation.sh
```

### Curve Selection

When prompted, choose an elliptic curve security level:

| Option | Curve | Security Level | Description |
|--------|-------|----------------|-------------|
| 1 | prime256v1 (P-256) | ~128-bit | Standard security, widely supported |
| 2 | secp384r1 (P-384) | ~192-bit | High security |
| 3 | secp521r1 (P-521) | ~256-bit | Very high security |

### Generated Artifacts

All files are stored in the `ecdh/` directory:

| File | Description |
|------|-------------|
| alice.key | Alice's private key |
| alice.pub | Alice's public key (sent to Bob) |
| bob.key | Bob's private key |
| bob.pub | Bob's public key (sent to Alice) |
| secret.alice | Shared secret derived by Alice |
| secret.bob | Shared secret derived by Bob |

### Example Output
```
--- ECDH Key Exchange Simulation ---
Select Elliptic Curve strength:
  [1] prime256v1 (P-256) - Standard security
  [2] secp384r1  (P-384) - High security
  [3] secp521r1  (P-521) - Very High security
Enter selection [1-3]: 1

Using Curve: prime256v1

1. Generating Keys for Alice and Bob... [OK]
2. Deriving Shared Secrets...
   Alice is calculating... [Done]
   Bob is calculating...   [Done]
3. Verifying consistency... [SUCCESS]
   Both parties derived the exact same secret.

Visual Proof (First 32 bytes of Hex):
Alice's Secret: a1b2c3d4e5f6...
Bob's Secret:   a1b2c3d4e5f6...

Artifacts stored in './ecdh/'
```