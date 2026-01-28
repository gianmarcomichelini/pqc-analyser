#!/bin/bash
# Load Common Utils & Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"
source "$CONFIG_FILE"

generate_key() {
    local alg=$1
    local name=$2
    local opts=$3

    local priv="$KEY_DIR/${name}.key"
    local pub="$KEY_DIR/${name}.pub"

    echo -n "  Generating $name... "
    # We use eval to handle the options string properly
    eval "openssl genpkey $opts -algorithm $alg -out $priv" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Derive public key (using the same opts/provider if needed)
        # Note: We strip -algorithm from opts for pkey command or just reuse provider flags
        # Simplest way for pkey is often just provider if needed.
        # However, $opts might contain -algorithm EC which pkey doesn't need, but it ignores usually.
        # Let's clean opts for pkey to be safe, mostly just keeping provider.
        
        local pkey_opts=""
        if [[ "$opts" == *"-provider oqsprovider"* ]]; then
            pkey_opts="-provider oqsprovider"
        fi

        eval "openssl pkey $pkey_opts -in $priv -pubout -out $pub" >/dev/null 2>&1
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${RED}[FAIL]${NC}"
    fi
}

log_info "Starting Key Generation..."

# 1. Falcon
case "${1:-all}" in
    "all"|"falcon")
        log_info "Family: Falcon"
        for alg in $FALCON_ALGOS; do 
            generate_key "$alg" "$alg" "-provider oqsprovider"
        done
        ;;
esac

# 2. ML-DSA
case "${1:-all}" in
    "all"|"mldsa")
        log_info "Family: ML-DSA"
        for alg in $MLDSA_ALGOS; do 
            generate_key "$alg" "$alg" "-provider oqsprovider"
        done
        ;;
esac

# 3. SPHINCS+
case "${1:-all}" in
    "all"|"sphincs")
        log_info "Family: SPHINCS+"
        for alg in $SPHINCS_ALGOS; do 
            generate_key "$alg" "$alg" "-provider oqsprovider"
        done
        ;;
esac

# 4. Classical (RSA & ECDSA)
case "${1:-all}" in
    "all"|"classical")
        log_info "Family: Classical"
        
        # RSA
        for bits in $RSA_BITS; do 
            generate_key "RSA" "rsa${bits}" "-pkeyopt rsa_keygen_bits:$bits"
        done

        # ECDSA (Fix applied here)
        for curve in $ECDSA_CURVES; do
            clean_name="ecdsa_$(echo $curve | tr -d '[:punct:]')"
            generate_key "EC" "$clean_name" "-pkeyopt ec_paramgen_curve:$curve"
        done
        ;;
esac

log_success "Key generation complete."