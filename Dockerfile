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

ENV LIBSODIUM_VERSION 1.0.11
ENV LIBSODIUM_SHA256 31505206b264c813869023405258bf3622a02619b69cc6028b02c4b2b8484607
ENV LIBSODIUM_DOWNLOAD_URL https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz

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

ENV DNSCRYPT_PROXY_VERSION 1.9.4
ENV DNSCRYPT_PROXY_SHA256 019f914a00230ae1f95c1c981acea30800fb342f36d29d06ecc75508f513b49d
ENV DNSCRYPT_PROXY_DOWNLOAD_URL https://download.dnscrypt.org/dnscrypt-proxy/dnscrypt-proxy-${DNSCRYPT_PROXY_VERSION}.tar.gz

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $DNSCRYPT_PROXY_DOWNLOAD_URL -o dnscrypt-proxy.tar.gz && \
    echo "${DNSCRYPT_PROXY_SHA256} *dnscrypt-proxy.tar.gz" | sha256sum -c - && \
    tar xzf dnscrypt-proxy.tar.gz && \
    rm -f dnscrypt-proxy.tar.gz && \
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
                   --ephemeral-keys
