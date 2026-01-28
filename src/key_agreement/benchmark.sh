#!/bin/bash

# ==========================================
# KEM (Key Encapsulation) Benchmark
# ==========================================

# 1. Load Common Utilities & Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# 2. Check Arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <pq/classical> <algorithm>"
    echo "Example: $0 pq ml-kem-768"
    exit 1
fi

TYPE=$1
ALGORITHM=$2
NUM_ITERATIONS=100

# 3. Setup Paths
# Note: In KEM, the "Receiver" generates the keypair.
KEY="$TEMP_DIR/bench_kem_${ALGORITHM}.key"
PUBKEY="$TEMP_DIR/bench_kem_${ALGORITHM}.pub"
CIPHERTEXT="$TEMP_DIR/bench_kem_${ALGORITHM}.ct"
SHARED_SECRET="$TEMP_DIR/bench_kem_${ALGORITHM}.ss"
CSV_FILE="$BENCH_DIR/kem.csv"

# 4. Cleanup Trap
cleanup() {
    rm -f "$KEY" "$PUBKEY" "$CIPHERTEXT" "$SHARED_SECRET"
}
trap cleanup EXIT

log_info "--- Setup: Generating temporary key pair in output/temp ---"

# 5. Key Generation Logic
if [ "$TYPE" == "pq" ]; then
    # Post-Quantum KEM Keygen (OQS)
    openssl genpkey -provider oqsprovider -algorithm "$ALGORITHM" -out "$KEY" > /dev/null 2>&1
    openssl pkey -provider oqsprovider -in "$KEY" -pubout -out "$PUBKEY" > /dev/null 2>&1
else
    # Classical ECDH Setup (Simulating KEM)
    # Default to Prime256v1 for standard comparison
    openssl ecparam -name prime256v1 -genkey -noout -out "$KEY" > /dev/null 2>&1
    openssl pkey -in "$KEY" -pubout -out "$PUBKEY" > /dev/null 2>&1
fi

# Validation
if [ ! -f "$KEY" ]; then
    log_error "Failed to generate key for $ALGORITHM. Check configuration."
    exit 1
fi

# 6. Benchmark: ENCAPSULATION (Sender)
# The Sender uses the Receiver's Public Key to generate Ciphertext + Secret
log_info "--- Benchmarking ENCAPSULATION ($NUM_ITERATIONS iterations) ---"
START_TIME=$(date +%s.%N)

for ((i=1; i<=NUM_ITERATIONS; i++)); do
    if [ "$TYPE" == "pq" ]; then
        openssl pkeyutl -provider oqsprovider -encap -pubin -inkey "$PUBKEY" \
            -out "$CIPHERTEXT" -secret "$SHARED_SECRET" > /dev/null 2>&1
    else
        # ECDH Simulation: "Encap" is essentially deriving the secret using the peer's public key
        # (Alice deriving secret from Bob's pubkey)
        openssl pkeyutl -derive -inkey "$KEY" -peerkey "$PUBKEY" \
            -out "$SHARED_SECRET" > /dev/null 2>&1
    fi
done

END_TIME=$(date +%s.%N)
ENCAP_ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
ENCAP_TPS=$(echo "$NUM_ITERATIONS / $ENCAP_ELAPSED" | bc -l)

# 7. Benchmark: DECAPSULATION (Receiver)
# The Receiver uses their Private Key + Ciphertext to recover the Secret
log_info "--- Benchmarking DECAPSULATION ($NUM_ITERATIONS iterations) ---"
START_TIME=$(date +%s.%N)

for ((i=1; i<=NUM_ITERATIONS; i++)); do
    if [ "$TYPE" == "pq" ]; then
        openssl pkeyutl -provider oqsprovider -decap -inkey "$KEY" \
            -in "$CIPHERTEXT" -secret "$SHARED_SECRET" > /dev/null 2>&1
    else
        # ECDH Simulation: "Decap" is symmetric to Encap in ECDH
        # (Bob deriving secret from Alice's pubkey - mathematically identical cost)
        openssl pkeyutl -derive -inkey "$KEY" -peerkey "$PUBKEY" \
            -out "$SHARED_SECRET" > /dev/null 2>&1
    fi
done

END_TIME=$(date +%s.%N)
DECAP_ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
DECAP_TPS=$(echo "$NUM_ITERATIONS / $DECAP_ELAPSED" | bc -l)

# 8. Console Output
echo ""
echo "Results for $ALGORITHM:"
printf "  Encapsulation: %.4f s (%.2f ops/sec)\n" "$ENCAP_ELAPSED" "$ENCAP_TPS"
printf "  Decapsulation: %.4f s (%.2f ops/sec)\n" "$DECAP_ELAPSED" "$DECAP_TPS"
echo ""

# 9. CSV Export
if [ ! -f "$CSV_FILE" ]; then
    echo "Timestamp,Type,Algorithm,Operation,Time_Total,Ops_Per_Sec" > "$CSV_FILE"
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Append data (Rows for both Encap and Decap)
echo "$TIMESTAMP,$TYPE,$ALGORITHM,Encap,$ENCAP_ELAPSED,$ENCAP_TPS" >> "$CSV_FILE"
echo "$TIMESTAMP,$TYPE,$ALGORITHM,Decap,$DECAP_ELAPSED,$DECAP_TPS" >> "$CSV_FILE"

log_success "Results saved to $CSV_FILE"