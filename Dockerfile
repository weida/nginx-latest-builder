# Build stage
FROM ubuntu:24.04 AS builder

LABEL maintainer="weida <caoweida2004@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
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

# Verify compilers
RUN which gcc && which cc || ln -s /usr/bin/gcc /usr/bin/cc

# Build nginx
COPY nginx-builder.sh /tmp/nginx-builder.sh
RUN bash /tmp/nginx-builder.sh && \
    rm -rf /usr/local/src/* /tmp/nginx-builder.sh

# Runtime stage
FROM ubuntu:24.04

LABEL maintainer="weida <caoweida2004@gmail.com>"
LABEL description="Nginx with HTTP/3 (QUIC) support - statically linked"

# Copy nginx from builder
COPY --from=builder /usr/local/nginx /usr/local/nginx

# Create nginx user
RUN useradd -r -s /sbin/nologin nginx

# Forward logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/nginx/logs/access.log && \
    ln -sf /dev/stderr /usr/local/nginx/logs/error.log

EXPOSE 80 443 443/udp

STOPSIGNAL SIGQUIT

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
