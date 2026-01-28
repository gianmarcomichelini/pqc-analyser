#!/bin/bash

# Path Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
# Source common colors
source "$PROJECT_ROOT/src/common.sh"

KEY_DIR="$PROJECT_ROOT/output/keys"
SIG_OUTPUT="$PROJECT_ROOT/output/signatures/manager_signed.sig"
MESSAGE_FILE="message.txt" 

# Ensure directories
mkdir -p "$PROJECT_ROOT/output/signatures"

# --- AUTO-FIX: Create message.txt if it is missing ---
if [ ! -f "$MESSAGE_FILE" ]; then
    echo -e "${BLUE}[INFO] message.txt not found. Creating a dummy file...${NC}"
    echo "This is a sample message created by pqc-cli for signing tests." > "$MESSAGE_FILE"
fi
# -----------------------------------------------------

if [ ! -d "$KEY_DIR" ]; then
    echo -e "${RED}Error: Key directory $KEY_DIR does not exist.${NC}"
    echo -e "${YELLOW}Please run key generation scripts first.${NC}"
    exit 1
fi

echo -e "${BLUE}--- Scanning for keys in output/keys ---${NC}"

# Find keys recursively
mapfile -t KEY_LIST < <(find "$KEY_DIR" -type f -name "*.key" | sort)

if [ ${#KEY_LIST[@]} -eq 0 ]; then
    echo -e "${RED}No keys found in $KEY_DIR${NC}"
    exit 1
fi

# Menu
i=1
for key in "${KEY_LIST[@]}"; do
    # Show relative path for readability
    display_name=$(echo "$key" | sed "s|$KEY_DIR/||")
    echo "  [$i] $display_name"
    ((i++))
done

read -p "Select a key (number): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#KEY_LIST[@]}" ]; then
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
fi

CHOSEN_KEY="${KEY_LIST[$((SELECTION-1))]}"
CHOSEN_PUB="${CHOSEN_KEY%.key}.pub"

if [ ! -f "$CHOSEN_PUB" ]; then
    echo -e "${RED}Error: Matching public key not found for $CHOSEN_KEY${NC}"
    exit 1
fi

# Auto-detect PQC vs Classical
if [[ "$CHOSEN_KEY" == *"mldsa"* ]] || [[ "$CHOSEN_KEY" == *"falcon"* ]] || [[ "$CHOSEN_KEY" == *"sphincs"* ]]; then
    CMD_SIGN="openssl dgst -provider oqsprovider -sign $CHOSEN_KEY -out $SIG_OUTPUT $MESSAGE_FILE"
    CMD_VERIFY="openssl dgst -provider oqsprovider -verify $CHOSEN_PUB -signature $SIG_OUTPUT $MESSAGE_FILE"
else
    # Handle Classical (RSA/ECDSA)
    CMD_SIGN="openssl dgst -sha256 -sign $CHOSEN_KEY -out $SIG_OUTPUT $MESSAGE_FILE"
    CMD_VERIFY="openssl dgst -sha256 -verify $CHOSEN_PUB -signature $SIG_OUTPUT $MESSAGE_FILE"
fi

echo -e "${BLUE}--- Signing ---${NC}"
eval "$CMD_SIGN" && echo -e "${GREEN}Signed to $SIG_OUTPUT${NC}"

echo -e "${BLUE}--- Verifying ---${NC}"
eval "$CMD_VERIFY" && echo -e "${GREEN}Verification Successful!${NC}"