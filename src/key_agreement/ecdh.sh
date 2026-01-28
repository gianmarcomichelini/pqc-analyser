#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
# Source common colors
source "$PROJECT_ROOT/src/common.sh"

OUTPUT_DIR="$PROJECT_ROOT/output/ecdh"

mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}--- ECDH Key Exchange Simulation ---${NC}"
echo "Select Curve:"
echo "  [1] prime256v1 (P-256)"
echo "  [2] secp384r1  (P-384)"
echo "  [3] secp521r1  (P-521)"
read -p "Enter selection [1-3]: " CHOICE

case $CHOICE in
    1) CURVE="prime256v1" ;;
    2) CURVE="secp384r1" ;;
    3) CURVE="secp521r1" ;;
    *) echo -e "${RED}Invalid selection.${NC}"; exit 1 ;;
esac

# Define filenames
ALICE_KEY="$OUTPUT_DIR/alice.key"
ALICE_PUB="$OUTPUT_DIR/alice.pub"
BOB_KEY="$OUTPUT_DIR/bob.key"
BOB_PUB="$OUTPUT_DIR/bob.pub"
SECRET_ALICE="$OUTPUT_DIR/secret.alice"
SECRET_BOB="$OUTPUT_DIR/secret.bob"

echo -e "${YELLOW}1. Generating Keys for Alice and Bob ($CURVE)...${NC}"
openssl ecparam -genkey -name "$CURVE" -out "$ALICE_KEY" 2>/dev/null
openssl pkey -in "$ALICE_KEY" -pubout -out "$ALICE_PUB" 2>/dev/null

openssl ecparam -genkey -name "$CURVE" -out "$BOB_KEY" 2>/dev/null
openssl pkey -in "$BOB_KEY" -pubout -out "$BOB_PUB" 2>/dev/null

echo -e "${YELLOW}2. Deriving Shared Secrets...${NC}"
# Alice: Her Priv + Bob Pub
openssl pkeyutl -derive -inkey "$ALICE_KEY" -peerkey "$BOB_PUB" -out "$SECRET_ALICE"
# Bob: His Priv + Alice Pub
openssl pkeyutl -derive -inkey "$BOB_KEY" -peerkey "$ALICE_PUB" -out "$SECRET_BOB"

echo -e "${YELLOW}3. Verifying...${NC}"
if diff "$SECRET_ALICE" "$SECRET_BOB" >/dev/null; then
    echo -e "${GREEN}  [SUCCESS] Both parties derived the same secret.${NC}"
    echo "  Artifacts saved in output/ecdh/"
else
    echo -e "${RED}  [FAILURE] Secrets do not match!${NC}"
fi