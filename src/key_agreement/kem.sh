#!/bin/bash

# Path Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
# Source common colors
source "$PROJECT_ROOT/src/common.sh"

KEY_DIR="$PROJECT_ROOT/output/keys"
ARTIFACT_DIR="$PROJECT_ROOT/output/kem"

mkdir -p "$ARTIFACT_DIR"

# (Colors are now sourced from common.sh)

echo -e "${BLUE}--- ML-KEM Key Exchange Simulation ---${NC}"
echo "Select Algorithm Level:"
echo "  [1] ML-KEM-512"
echo "  [2] ML-KEM-768"
echo "  [3] ML-KEM-1024"
read -p "Enter selection [1-3]: " CHOICE

case $CHOICE in
    1) LEVEL="512" ;;
    2) LEVEL="768" ;;
    3) LEVEL="1024" ;;
    *) echo -e "${RED}Invalid selection.${NC}"; exit 1 ;;
esac

ALGO="ml-kem-$LEVEL"
PUB_KEY="${KEY_DIR}/mlkem${LEVEL}_pub.pem"
PRIV_KEY="${KEY_DIR}/mlkem${LEVEL}_priv.pem"

# Artifacts
CIPHERTEXT="${ARTIFACT_DIR}/mlkem${LEVEL}.ct"
SS_SENDER="${ARTIFACT_DIR}/mlkem${LEVEL}.ss.sender"
SS_RECEIVER="${ARTIFACT_DIR}/mlkem${LEVEL}.ss.receiver"

# 1. Prerequisite Check
if [ ! -f "$PUB_KEY" ] || [ ! -f "$PRIV_KEY" ]; then
    echo -e "${RED}[Error] Keys for $ALGO not found in output/keys!${NC}"
    echo -e "${YELLOW}Please run: ./bin/pqc-cli kem keygen${NC}"
    exit 1
fi

# 2. Encapsulate (Sender)
echo -n "1. Encapsulating (Sender)... "
openssl pkeyutl -provider oqsprovider -encap \
    -pubin -inkey "$PUB_KEY" \
    -out "$CIPHERTEXT" \
    -secret "$SS_SENDER"

if [ $? -eq 0 ]; then echo -e "${GREEN}[OK]${NC}"; else echo -e "${RED}[FAIL]${NC}"; exit 1; fi

# 3. Decapsulate (Receiver)
echo -n "2. Decapsulating (Receiver)... "
openssl pkeyutl -provider oqsprovider -decap \
    -inkey "$PRIV_KEY" \
    -in "$CIPHERTEXT" \
    -secret "$SS_RECEIVER"

if [ $? -eq 0 ]; then echo -e "${GREEN}[OK]${NC}"; else echo -e "${RED}[FAIL]${NC}"; exit 1; fi

# 4. Verify
echo -n "3. Verifying Shared Secrets... "
DIFF_OUT=$(diff "$SS_SENDER" "$SS_RECEIVER")

if [ -z "$DIFF_OUT" ]; then
    echo -e "${GREEN}[SUCCESS] Secrets Match!${NC}"
else
    echo -e "${RED}[FAILURE] Secrets do not match.${NC}"
fi