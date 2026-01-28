# PQC Analyser: Post-Quantum Cryptography Benchmarking Suite

A Dockerized environment for analyzing, benchmarking, and simulating Post-Quantum Cryptography (PQC) algorithms. This suite features a custom build of **OpenSSL 3.6.0** integrated with **liboqs** and the **OQS Provider**, enabling you to test algorithms like **ML-DSA (Dilithium)**, **Falcon**, **SPHINCS+**, and **ML-KEM (Kyber)** alongside classical RSA and ECDSA.

## Quick Start

### 1. Build and Start the Environment

Build the container from the project root. This compiles OpenSSL and liboqs from source (takes ~5-10 mins initially):
```bash
docker compose up -d --build
```

### 2. Enter the Container

Access the running Linux environment:
```bash
docker exec -it pqc-analyser bash
```

Your prompt will change to `root@...:/app#`.

---


## 🔑  Key Generation (Required First)

**You must generate keys before running any benchmarks.**

```bash
# Generate keys for ALL algorithms (Recommended)
./bin/pqc-cli sign keygen all

# Generate specific families
./bin/pqc-cli sign keygen mldsa     # ML-DSA (Dilithium)
./bin/pqc-cli sign keygen falcon    # Falcon
./bin/pqc-cli sign keygen classical # RSA & ECDSA
./bin/pqc-cli kem keygen            # ML-KEM (Kyber)
```

---

## ⏱️ Benchmarking Performance

These commands run speed tests and save results to `output/benchmarks/`.

### Digital Signatures (Signing & Verification)

**Usage:** `./bin/pqc-cli sign bench <pq/classical> <algorithm> <message_file>`

```bash
# ML-DSA (Dilithium)
./bin/pqc-cli sign bench pq ml-dsa-44 message.txt
./bin/pqc-cli sign bench pq ml-dsa-65 message.txt
./bin/pqc-cli sign bench pq ml-dsa-87 message.txt

# Falcon
./bin/pqc-cli sign bench pq falcon512 message.txt
./bin/pqc-cli sign bench pq falcon1024 message.txt

# Classical (Standard)
./bin/pqc-cli sign bench classical ecdsa message.txt
./bin/pqc-cli sign bench classical rsa message.txt
```

### Key Encapsulation (Encapsulation & Decapsulation)

**Usage:** `./bin/pqc-cli kem bench <pq/classical> <algorithm>`

```bash
# ML-KEM (Kyber)
./bin/pqc-cli kem bench pq ml-kem-512
./bin/pqc-cli kem bench pq ml-kem-768
./bin/pqc-cli kem bench pq ml-kem-1024
```

---

## 🔬 Simulations & Interactive Tools

Visual demonstrations of how the cryptography works step-by-step.

```bash
# Interactive Signing Manager (Sign/Verify files manually)
./bin/pqc-cli sign manage

# Post-Quantum Key Exchange Simulation (Kyber)
./bin/pqc-cli kem sim

# Classical Key Exchange Simulation (ECDH)
./bin/pqc-cli kem ecdh
```

---

## 🚀 "Run Everything" Script (To Populate CSV)

Paste this entire block into your container terminal to run all benchmarks sequentially. This ensures your Excel/CSV report is full.

```bash
# 1. Create dummy message
echo "Benchmark Test Data" > message.txt

# 2. Run Signature Benchmarks
echo "--- Benchmarking Signatures ---"
./bin/pqc-cli sign bench pq ml-dsa-65 message.txt
./bin/pqc-cli sign bench pq falcon512 message.txt
./bin/pqc-cli sign bench classical ecdsa message.txt

# 3. Run KEM Benchmarks
echo "--- Benchmarking KEM ---"
./bin/pqc-cli kem bench pq ml-kem-768
./bin/pqc-cli kem bench pq ml-kem-1024

echo "Done! Check output/benchmarks/ folder."
```

---
