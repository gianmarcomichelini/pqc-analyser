#!/bin/bash

# Path Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
# Source common colors
source "$PROJECT_ROOT/src/common.sh"

OUTPUT_DIR="$PROJECT_ROOT/output/keys"

mkdir -p "$OUTPUT_DIR"

echo -e "\n${BLUE}--- Starting ML-KEM Key Generation ---${NC}"
echo -e "Saving keys to: ${YELLOW}$OUTPUT_DIR/${NC}"

for LEVEL in 512 768 1024; do
    ALGO="ml-kem-$LEVEL"
    PRIV_FILE="${OUTPUT_DIR}/mlkem${LEVEL}_priv.pem"
    PUB_FILE="${OUTPUT_DIR}/mlkem${LEVEL}_pub.pem"

    echo -n "Processing $ALGO... "

    # Generate Private Key
    openssl genpkey -provider oqsprovider -algorithm "$ALGO" \
        -provparam ml-kem.retain_seed=no \
        -out "$PRIV_FILE" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        # Derive Public Key
        openssl pkey -provider oqsprovider -in "$PRIV_FILE" -pubout -out "$PUB_FILE" >/dev/null 2>&1
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${RED}[FAIL]${NC}"
        exit 1
    fi
done

echo -e "\n${GREEN}All ML-KEM keys have been generated.${NC}"