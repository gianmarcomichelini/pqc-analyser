#!/bin/bash

# ==========================================
# Digital Signatures Benchmark
# ==========================================

# 1. Load Common Utilities & Config
#    (Assumes this script is located in src/digital_signatures/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# 2. Check Arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <pq/classical> <algorithm> <file_to_sign> [ecdsa_curve]"
    echo "Example: $0 pq ml-dsa-65 message.txt"
    exit 1
fi

TYPE=$1
ALGORITHM=$2
MESSAGE=$3
CURVE_ARG=$4
NUM_ITERATIONS=100

# 3. Setup Paths (using variables from common.sh)
KEY="$TEMP_DIR/bench_${ALGORITHM}.key"
PUBKEY="$TEMP_DIR/bench_${ALGORITHM}.pub"
SIGNATURE="$TEMP_DIR/bench_${ALGORITHM}.sig"
CSV_FILE="$BENCH_DIR/signatures.csv"

# 4. Cleanup Trap
cleanup() {
    rm -f "$KEY" "$PUBKEY" "$SIGNATURE"
}
trap cleanup EXIT

log_info "--- Setup: Generating temporary key pair in output/temp ---"

# 5. Key Generation Logic
if [ "$TYPE" == "pq" ]; then
    # Post-Quantum (OQS Provider)
    openssl genpkey -provider oqsprovider -algorithm "$ALGORITHM" -out "$KEY" > /dev/null 2>&1
    openssl pkey -provider oqsprovider -in "$KEY" -pubout -out "$PUBKEY" > /dev/null 2>&1
else
    # Classical Logic
    if [ "$ALGORITHM" == "ecdsa" ]; then
        CURVE="${CURVE_ARG:-prime256v1}"
        openssl ecparam -name "$CURVE" -genkey -noout -out "$KEY" > /dev/null 2>&1
    elif [ "$ALGORITHM" == "rsa" ]; then
        openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out "$KEY" > /dev/null 2>&1
    else
        # Generic fallback
        openssl genpkey -algorithm "$ALGORITHM" -out "$KEY" > /dev/null 2>&1
    fi
    openssl pkey -in "$KEY" -pubout -out "$PUBKEY" > /dev/null 2>&1
fi

# Validation
if [ ! -f "$KEY" ]; then
    log_error "Failed to generate key for $ALGORITHM. Check if algorithm name is correct."
    exit 1
fi

# 6. Benchmarking: Signing
log_info "--- Benchmarking SIGNING ($NUM_ITERATIONS iterations) ---"
START_TIME=$(date +%s.%N)

for ((i=1; i<=NUM_ITERATIONS; i++)); do
    if [ "$TYPE" == "pq" ]; then
        openssl dgst -provider oqsprovider -sign "$KEY" -out "$SIGNATURE" "$MESSAGE" > /dev/null 2>&1
    else
        openssl dgst -sha256 -sign "$KEY" -out "$SIGNATURE" "$MESSAGE" > /dev/null 2>&1
    fi
done

END_TIME=$(date +%s.%N)
SIGN_ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
SIGN_TPS=$(echo "$NUM_ITERATIONS / $SIGN_ELAPSED" | bc -l)

# 7. Benchmarking: Verification
log_info "--- Benchmarking VERIFICATION ($NUM_ITERATIONS iterations) ---"
START_TIME=$(date +%s.%N)

for ((i=1; i<=NUM_ITERATIONS; i++)); do
    if [ "$TYPE" == "pq" ]; then
        openssl dgst -provider oqsprovider -verify "$PUBKEY" -signature "$SIGNATURE" "$MESSAGE" > /dev/null 2>&1
    else
        openssl dgst -sha256 -verify "$PUBKEY" -signature "$SIGNATURE" "$MESSAGE" > /dev/null 2>&1
    fi
done

END_TIME=$(date +%s.%N)
VERIFY_ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
VERIFY_TPS=$(echo "$NUM_ITERATIONS / $VERIFY_ELAPSED" | bc -l)

# 8. Console Output
echo ""
echo "Results for $ALGORITHM:"
printf "  Signing:      %.4f s (%.2f ops/sec)\n" "$SIGN_ELAPSED" "$SIGN_TPS"
printf "  Verification: %.4f s (%.2f ops/sec)\n" "$VERIFY_ELAPSED" "$VERIFY_TPS"
echo ""

# 9. CSV Export (Data Persistence)
# Initialize CSV header if file doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "Timestamp,Type,Algorithm,Operation,Time_Total,Ops_Per_Sec" > "$CSV_FILE"
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Append data
echo "$TIMESTAMP,$TYPE,$ALGORITHM,Sign,$SIGN_ELAPSED,$SIGN_TPS" >> "$CSV_FILE"
echo "$TIMESTAMP,$TYPE,$ALGORITHM,Verify,$VERIFY_ELAPSED,$VERIFY_TPS" >> "$CSV_FILE"

log_success "Results saved to $CSV_FILE"