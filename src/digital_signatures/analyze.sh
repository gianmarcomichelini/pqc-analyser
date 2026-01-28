#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
# Source common colors
source "$PROJECT_ROOT/src/common.sh"

TEMP_DIR="$PROJECT_ROOT/output/temp"
mkdir -p "$TEMP_DIR"

if [ "$#" -lt 2 ]; then
    echo -e "${RED}Usage: $0 <pq/classical> <algorithm>${NC}"
    exit 1
fi

TYPE=$1
ALGO=$2
MESSAGE="$TEMP_DIR/size_test_msg.txt"
KEY_FILE="$TEMP_DIR/temp_size.key"
PUB_FILE="$TEMP_DIR/temp_size.pub"
SIG_FILE="$TEMP_DIR/temp_size.sig"

# Create dummy message
echo "Dummy content" > "$MESSAGE"

cleanup() { rm -f "$KEY_FILE" "$PUB_FILE" "$SIG_FILE" "$MESSAGE"; }
trap cleanup EXIT

# Generation Logic
if [ "$TYPE" == "pq" ]; then
    CLEAN_ALGO=$(echo "$ALGO" | tr -d '-')
    openssl genpkey -provider oqsprovider -algorithm "$CLEAN_ALGO" -out "$KEY_FILE" >/dev/null 2>&1
    openssl pkey -provider oqsprovider -in "$KEY_FILE" -pubout -out "$PUB_FILE" >/dev/null 2>&1
    openssl dgst -provider oqsprovider -sign "$KEY_FILE" -out "$SIG_FILE" "$MESSAGE" >/dev/null 2>&1
else
    # Standard OpenSSL logic
    openssl genpkey -algorithm "$ALGO" -out "$KEY_FILE" >/dev/null 2>&1
    openssl pkey -in "$KEY_FILE" -pubout -out "$PUB_FILE" >/dev/null 2>&1
    openssl dgst -sha256 -sign "$KEY_FILE" -out "$SIG_FILE" "$MESSAGE" >/dev/null 2>&1
fi

# Analysis
PUB_SIZE=$(stat -c%s "$PUB_FILE")
SIG_SIZE=$(stat -c%s "$SIG_FILE")

echo -e "${BLUE}Analysis for $ALGO:${NC}"
echo -e "  Public Key: ${YELLOW}$PUB_SIZE bytes${NC}"
echo -e "  Signature:  ${YELLOW}$SIG_SIZE bytes${NC}"