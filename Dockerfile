FROM ubuntu:24.04

LABEL maintainer="weida <caoweida2004@gmail.com>"
LABEL description="Nginx with HTTP/3 (QUIC) and Post-Quantum Cryptography support"

ENV DEBIAN_FRONTEND=noninteractive

# Install all build dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    wget \
    tar \
    libtool \
    cmake \
    curl \
    ca-certificates \
    perl \
    autoconf \
    automake && \
    rm -rf /var/lib/apt/lists/*

# Verify compilers are installed
RUN which gcc && which cc || ln -s /usr/bin/gcc /usr/bin/cc && \
    gcc --version && \
    cc --version && \
    make --version

# Copy and run build script
COPY nginx-builder.sh /tmp/nginx-builder.sh
RUN bash /tmp/nginx-builder.sh && \
    rm -rf /usr/local/src/* /tmp/nginx-builder.sh

# Forward logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/nginx/logs/access.log && \
    ln -sf /dev/stderr /usr/local/nginx/logs/error.log

EXPOSE 80 443 443/udp

STOPSIGNAL SIGQUIT

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
