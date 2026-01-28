FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    bc \
    perl \
    cmake \
    autoconf \
    libtool \
    zlib1g-dev \
    git \
    wget \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

ENV WORKSPACE="/opt/quantumsafe"
ENV BUILD_DIR="${WORKSPACE}/build"

RUN mkdir -p ${WORKSPACE} ${BUILD_DIR}/lib64 \
    && ln -s ${BUILD_DIR}/lib64 ${BUILD_DIR}/lib

WORKDIR ${WORKSPACE}
RUN git clone --branch openssl-3.6.0 --depth 1 https://github.com/openssl/openssl.git \
    && cd openssl \
    && ./Configure --prefix=${BUILD_DIR} no-ssl no-tls1 no-tls1_1 no-afalgeng no-shared threads -lm \
    && make -j $(nproc) \
    && make -j $(nproc) install_sw install_ssldirs

WORKDIR ${WORKSPACE}
RUN git clone https://github.com/open-quantum-safe/liboqs.git \
    && cd liboqs \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=${BUILD_DIR} \
             -DBUILD_SHARED_LIBS=ON \
             -DOQS_USE_OPENSSL=OFF \
             -DCMAKE_BUILD_TYPE=Release \
             -DOQS_BUILD_ONLY_LIB=ON \
             -DOQS_DIST_BUILD=ON \
             .. \
    && make -j $(nproc) \
    && make -j $(nproc) install

WORKDIR ${WORKSPACE}
RUN git clone https://github.com/open-quantum-safe/oqs-provider.git \
    && cd oqs-provider \
    && liboqs_DIR=${BUILD_DIR} cmake -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/oqs-provider \
             -DOPENSSL_ROOT_DIR=${BUILD_DIR} \
             -DCMAKE_BUILD_TYPE=Release \
             -S . -B _build \
    && cmake --build _build \
    && cp _build/lib/* ${BUILD_DIR}/lib/

RUN sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${BUILD_DIR}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${BUILD_DIR}/ssl/openssl.cnf





WORKDIR ${WORKSPACE}
RUN git clone --depth 1 https://github.com/curl/curl.git \
    && cd curl \
    && autoreconf -fi \
    && ./configure LIBS="-lssl -lcrypto -lz" \
       LDFLAGS="-Wl,-rpath,${BUILD_DIR}/lib64 -L${BUILD_DIR}/lib64 -Wl,-rpath,${BUILD_DIR}/lib -L${BUILD_DIR}/lib" \
       CFLAGS="-O3 -fPIC" \
       --prefix=${BUILD_DIR} \
       --with-ssl=${BUILD_DIR} \
       --with-zlib \
       --enable-optimize --enable-libcurl-option --enable-libgcc --enable-shared \
       --enable-versioned-symbols \
       --disable-manual \
       --without-default-ssl-backend \
       --without-librtmp --without-libidn2 \
       --without-gnutls --without-mbedtls \
       --without-wolfssl --without-libpsl \
    && make -j $(nproc) \
    && make -j $(nproc) install






WORKDIR /app

COPY src ./src
COPY bin ./bin
COPY config ./config
COPY setup ./setup

ENV OPENSSL_CONF="${BUILD_DIR}/ssl/openssl.cnf"
ENV OPENSSL_MODULES="${BUILD_DIR}/lib"
ENV PATH="${BUILD_DIR}/bin:${BUILD_DIR}:${PATH}"
ENV LD_LIBRARY_PATH="${BUILD_DIR}/lib:${LD_LIBRARY_PATH}"

RUN chmod +x ./bin/pqc-cli \
    && chmod +x ./src/key_generation/*.sh 2>/dev/null || true \
    && chmod +x ./src/digital_signatures/*.sh 2>/dev/null || true \
    && chmod +x ./src/key_agreement/*.sh 2>/dev/null || true

CMD ["/bin/bash"]