FROM debian:8
MAINTAINER dnscrypt.io

ENV BUILD_DEPENDENCIES \
    autoconf \
    bzip2 \
    curl \
    gcc \
    make

RUN set -x && \
    apt-get update && \
    apt-get install -y $BUILD_DEPENDENCIES # --no-install-recommends

ENV LIBSODIUM_VERSION 1.0.12
ENV LIBSODIUM_SHA256 b8648f1bb3a54b0251cf4ffa4f0d76ded13977d4fa7517d988f4c902dd8e2f95
ENV LIBSODIUM_DOWNLOAD_URL https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION}/libsodium-${LIBSODIUM_VERSION}.tar.gz

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $LIBSODIUM_DOWNLOAD_URL -o libsodium.tar.gz && \
    echo "${LIBSODIUM_SHA256} *libsodium.tar.gz" | sha256sum -c - && \
    tar xzf libsodium.tar.gz && \
    rm -f libsodium.tar.gz && \
    cd libsodium-${LIBSODIUM_VERSION} && \
    ./configure --disable-dependency-tracking --enable-minimal --prefix=/opt/libsodium && \
    make check && make install && \
    echo /opt/libsodium/lib > /etc/ld.so.conf.d/libsodium.conf && ldconfig && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV DNSCRYPT_PROXY_VERSION 1.9.5
ENV DNSCRYPT_PROXY_SHA256 e89f5b9039979ab392302faf369ef7593155d5ea21580402a75bbc46329d1bb6
ENV DNSCRYPT_PROXY_DOWNLOAD_URL https://github.com/jedisct1/dnscrypt-proxy/releases/download/${DNSCRYPT_PROXY_VERSION}/dnscrypt-proxy-${DNSCRYPT_PROXY_VERSION}.tar.bz2

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $DNSCRYPT_PROXY_DOWNLOAD_URL -o dnscrypt-proxy.tar.bz2 && \
    echo "${DNSCRYPT_PROXY_SHA256} *dnscrypt-proxy.tar.bz2" | sha256sum -c - && \
    tar xjf dnscrypt-proxy.tar.bz2 && \
    rm -f dnscrypt-proxy.tar.bz2 && \
    cd dnscrypt-proxy-${DNSCRYPT_PROXY_VERSION} && \
    mkdir -p /opt/dnscrypt-proxy/empty && \
    groupadd _dnscrypt-proxy && \
    useradd -g _dnscrypt-proxy -s /etc -d /opt/dnscrypt-proxy/empty _dnscrypt-proxy && \
    env CPPFLAGS=-I/opt/libsodium/include LDFLAGS=-L/opt/libsodium/lib \
        ./configure --disable-dependency-tracking --prefix=/opt/dnscrypt-proxy --disable-plugins && \
    make install && \
    rm -fr /opt/dnscrypt-proxy/share && \
    rm -fr /tmp/* /var/tmp/*

RUN set -x && \
    apt-get purge -y --auto-remove $BUILD_DEPENDENCIES && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LISTEN_ADDR 0.0.0.0:53
ENV RESOLVER_ADDR 176.56.237.171:443
ENV PROVIDER_NAME 2.dnscrypt-cert.resolver1.dnscrypt.eu
ENV PROVIDER_KEY 67C0:0F2C:21C5:5481:45DD:7CB4:6A27:1AF2:EB96:9931:40A3:09B6:2B8D:1653:1185:9C66 
ENV LOGLEVEL 6
ENV EDNS_PAYLOAD_SIZE 1252

EXPOSE 53/tcp 53/udp

CMD /opt/dnscrypt-proxy/sbin/dnscrypt-proxy \
                   --user=_dnscrypt-proxy \
                   --local-address=$LISTEN_ADDR \
                   --provider-name=$PROVIDER_NAME \
                   --provider-key=$PROVIDER_KEY \
                   --resolver-address=$RESOLVER_ADDR \
                   --loglevel=$LOGLEVEL \
                   --edns-payload-size=$EDNS_PAYLOAD_SIZE \
                   --ephemeral-keys \
                   /opt/dnscrypt-proxy/etc/dnscrypt-proxy.conf
