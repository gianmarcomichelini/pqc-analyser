#!/bin/bash


print_frame() {
    local message="$1"
    local border_char="${2:-#}"  # Default border character is '#'
    local border_width=60        # Width of the border
    local padding=2              # Padding lines before and after the message

    # Print the top border
    printf "%${border_width}s\n" | tr " " "$border_char"

    # Add padding before the message
    for ((i = 0; i < padding; i++)); do
        printf "$border_char%$((border_width - 2))s$border_char\n" ""
    done

    # Center the message
    local message_length=${#message}
    local left_padding=$(((border_width - 2 - message_length) / 2))
    printf "$border_char%${left_padding}s%s%$((border_width - 2 - left_padding - message_length))s$border_char\n" "" "$message" ""

    # Add padding after the message
    for ((i = 0; i < padding; i++)); do
        printf "$border_char%$((border_width - 2))s$border_char\n" ""
    done

    # Print the bottom border
    printf "%${border_width}s\n" | tr " " "$border_char"
}

print_frame "Step 0/3: Install dependencies"
sudo apt update
sudo apt -y install git build-essential perl cmake autoconf libtool zlib1g-dev

print_frame "Installation Complete!" "*"
mkdir $HOME/quantumsafe
export WORKSPACE=$HOME/quantumsafe # set this to a working dir of your choice
export BUILD_DIR=$WORKSPACE/build # this will contain all the build artifacts
mkdir -p $BUILD_DIR/lib64
ln -s $BUILD_DIR/lib64 $BUILD_DIR/lib

print_frame "Step 1/3: Install OpenSSL"
cd $WORKSPACE
git clone --branch openssl-3.6.0 --depth 1 https://github.com/openssl/openssl.git
cd openssl

./Configure \
  --prefix=$BUILD_DIR \
  no-ssl no-tls1 no-tls1_1 no-afalgeng \
  no-shared threads -lm

make -j $(nproc)
make -j $(nproc) install_sw install_ssldirs
print_frame "Installation Complete!" "*"


print_frame "Step 2/3: Install liboqs"
cd $WORKSPACE

git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs

mkdir build && cd build

cmake \
  -DCMAKE_INSTALL_PREFIX=$BUILD_DIR \
  -DBUILD_SHARED_LIBS=ON \
  -DOQS_USE_OPENSSL=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DOQS_BUILD_ONLY_LIB=ON \
  -DOQS_DIST_BUILD=ON \
  ..

make -j $(nproc)
make -j $(nproc) install
print_frame "Installation Complete!" "*"

print_frame "Step 3/3: Install Open Quantum Safe provider for OpenSSL 3"
cd $WORKSPACE

git clone https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider

liboqs_DIR=$BUILD_DIR cmake \
  -DCMAKE_INSTALL_PREFIX=$WORKSPACE/oqs-provider \
  -DOPENSSL_ROOT_DIR=$BUILD_DIR \
  -DCMAKE_BUILD_TYPE=Release \
  -S . \
  -B _build
cmake --build _build

# Manually copy the lib files into the build dir
cp _build/lib/* $BUILD_DIR/lib/

print_frame "Installation Complete!" "*"
# We need to edit the openssl config to use the oqsprovider
sudo sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" $BUILD_DIR/ssl/openssl.cnf &&
sudo sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" $BUILD_DIR/ssl/openssl.cnf

echo -e "For OpenSSL to use the provider we just built, we will need to set two environment variables."
echo -e "If you plan to use this build long-term you will want to set these environment variables in your bashrc"
echo -e "otherwise, you will need to set them every time you start a new shell."

# These env vars need to be set for the oqsprovider to be used when using OpenSSL
export OPENSSL_CONF=$BUILD_DIR/ssl/openssl.cnf
export OPENSSL_MODULES=$BUILD_DIR/lib
$BUILD_DIR/bin/openssl list -providers -verbose -provider oqsprovider



echo -e "------------------------------------------------------------------"
echo -e "Step 5: Forcing our Linux distro to use the quantum-safe version of OpenSSL"
alias openssl=$BUILD_DIR/bin/openssl

echo -e "Done! Now you have OpenSSL with OQS Provider. You are able to test new quantum-safe algorithms!"

print_frame "Last step: Install cURL to use quantum-safe algorithms"
cd $WORKSPACE

git clone https://github.com/curl/curl.git
cd curl

autoreconf -fi
./configure \
  LIBS="-lssl -lcrypto -lz" \
  LDFLAGS="-Wl,-rpath,$BUILD_DIR/lib64 -L$BUILD_DIR/lib64 -Wl,-rpath,$BUILD_DIR/lib -L$BUILD_DIR/lib -Wl,-rpath,/lib64 -L/lib64 -Wl,-rpath,/lib -L/lib" \
  CFLAGS="-O3 -fPIC" \
  --prefix=$BUILD_DIR \
  --with-ssl=$BUILD_DIR \
  --with-zlib=/ \
  --enable-optimize --enable-libcurl-option --enable-libgcc --enable-shared \
  --enable-ldap=no --enable-ipv6 --enable-versioned-symbols \
  --disable-manual \
  --without-default-ssl-backend \
  --without-librtmp --without-libidn2 \
  --without-gnutls --without-mbedtls \
  --without-wolfssl --without-libpsl

make -j $(nproc)
make -j $(nproc) install

print_frame "Installation Complete!" "*"
alias curl=$BUILD_DIR/curl