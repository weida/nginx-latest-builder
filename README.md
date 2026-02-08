# Build New Nginx with Latest Dependencies

This script automates the process of downloading and compiling the latest versions of **PCRE2**, **zlib**, **OpenSSL**, **liboqs**, and **Nginx**. It retrieves the latest releases from GitHub, compiles them statically, and installs a fully functional version of Nginx with **HTTP/3**, **TLS 1.3**, and **Post-Quantum Cryptography** support.

---

## Features

- ✅ **HTTP/2** support
- ✅ **HTTP/3 (QUIC)** support
- ✅ **TLS 1.3** with modern cipher suites
- ✅ **Post-Quantum Cryptography** via liboqs
- ✅ Automatically fetches the latest mainline versions from GitHub for:
  - PCRE2
  - zlib
  - OpenSSL
  - liboqs (Open Quantum Safe)
  - Nginx
- ✅ Multi-architecture Docker images (x86_64, ARM64)
- ✅ Automated CI/CD builds and releases

---

## Quick Start

### Option 1: Docker (Recommended)

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  caoweida2004/nginx-http3:latest
```

See [README-Docker.md](README-Docker.md) for detailed Docker usage.

### Option 2: Build from Source

```bash
bash <(curl -L https://raw.githubusercontent.com/weida/nginx-http3-builder/refs/heads/main/nginx-builder.sh)
```

---

## Supported Operating Systems

This script has been successfully tested on the following systems:

- **Ubuntu**: 24.04.1 LTS
- **CentOS**: CentOS Linux release 7.9.2009
- **Alibaba Cloud Linux**: Alibaba Cloud Linux release 3 (Soaring Falcon)

---

## Prerequisites

The script automatically detects your package manager (`yum` for CentOS or `apt` for Ubuntu) and installs the required packages. Minimal build tools include:

- **gcc**
- **make**
- **wget**
- **tar**
- **libtool**

For CentOS, **perl-IPC-Cmd** is also required. These dependencies will be installed automatically by the script.

---

## Usage

### Install and Build Nginx

Run the following command to download and execute the script, building the latest version of Nginx:

```bash
bash <(curl -L https://raw.githubusercontent.com/weida/nginx-http3-builder/refs/heads/main/nginx-builder.sh)
```

### Output Example

After the script completes, you’ll see the Nginx version and linked library details:

```plaintext
=== Checking Nginx version ===
nginx version: nginx/1.27.3
built by gcc 10.2.1 20200825 (Alibaba 10.2.1-3.8 2.32) (GCC)
built with OpenSSL 3.4.0 22 Oct 2024
TLS SNI support enabled
configure arguments: --prefix=/usr/local/nginx --user=nginx --group=nginx ...
```

```plaintext
=== Done. Nginx installed to /usr/local/nginx ===
    PCRE2:   10.44
    zlib:    1.3.1
    OpenSSL: 3.4.0
    Nginx:   1.27.3
```

---

## Configuration Details

### Libraries and Versions

The script detects and uses the latest tags for:

- **PCRE2**: Latest version (e.g., `10.44`)
- **zlib**: Latest version (e.g., `1.3.1`)
- **OpenSSL**: Latest version (e.g., `3.4.0`)
- **Nginx**: Latest version (e.g., `1.27.3`)

### Static Compilation

All libraries are statically linked with Nginx, ensuring a self-contained binary.

### TLS 1.3 Support

OpenSSL is compiled with the `enable-tls1_3` option to provide full TLS 1.3 support.

---

## Nginx Build Options

The script configures Nginx with the following default options:

```bash
--with-http_ssl_module \
--with-http_v2_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_sub_module \
--with-pcre=/path/to/pcre2 \
--with-zlib=/path/to/zlib \
--with-openssl=/path/to/openssl \
--with-openssl-opt="enable-tls1_3" \
--with-cc-opt="-O2" \
--with-ld-opt="-Wl,-rpath,/usr/local/lib"
```

### Customization

You can modify these options in the script to add or remove features according to your requirements. Refer to the [official Nginx documentation](http://nginx.org/en/docs/) for a full list of available configuration options.

---

## Notes

1. The script automatically installs dependencies using the detected package manager (`yum` or `apt`).
2. Ensure sufficient disk space and administrative privileges before running the script.
3. If your distribution is not listed under **Supported Operating Systems**, you may need to make manual adjustments.
