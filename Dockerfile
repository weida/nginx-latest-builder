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
    rm -rf /usr/local/src/* /tmp/nginx-builder.sh && \
    ln -sf /dev/stdout /usr/local/nginx/logs/access.log && \
    ln -sf /dev/stderr /usr/local/nginx/logs/error.log

# Runtime stage
FROM gcr.io/distroless/base-debian12

LABEL maintainer="weida <caoweida2004@gmail.com>"
LABEL description="Nginx with HTTP/3 (QUIC) support - statically linked - minimal image"

# Copy nginx from builder
COPY --from=builder /usr/local/nginx /usr/local/nginx

# Distroless already has nonroot user, create nginx user via passwd/group files
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

EXPOSE 80 443 443/udp

STOPSIGNAL SIGQUIT

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
