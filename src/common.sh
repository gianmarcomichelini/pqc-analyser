#!/bin/bash

# ==========================================
# Common Utilities & Configuration
# ==========================================

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$COMMON_DIR")"

# Export Directories
export OUTPUT_DIR="$PROJECT_ROOT/output"
export KEY_DIR="$OUTPUT_DIR/keys"
export TEMP_DIR="$OUTPUT_DIR/temp"
export BENCH_DIR="$OUTPUT_DIR/benchmarks"
export CONFIG_FILE="$PROJECT_ROOT/config/algorithms.conf"

mkdir -p "$KEY_DIR" "$TEMP_DIR" "$BENCH_DIR"

# Colors
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export NC='\033[0m'

# Helper Functions
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check OQS
check_oqs_provider() {
    # In the new Dockerfile, 'openssl' is already the custom one
    if ! openssl list -providers | grep -q "oqsprovider"; then
         log_error "OQS Provider not found! Ensure you are running inside the Docker container."
         # Debug info
         echo "OPENSSL_CONF: $OPENSSL_CONF"
         echo "OPENSSL_MODULES: $OPENSSL_MODULES"
         echo "Path: $(which openssl)"
         exit 1
    fi
}