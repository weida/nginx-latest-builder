# NGINX ECH Example

This example runs NGINX in ECH shared mode:

- `public.example.test` is the visible ECH public name.
- `hidden.example.test` is the protected service name in the inner ClientHello.
- NGINX reads `ech/public.example.test.pem.ech` through `ssl_ech_file`.
- Access logs include `$ssl_ech_status` and `$ssl_ech_outer_server_name` so the test can prove whether ECH was used.

## Requirements

- Docker Compose
- OpenSSL 4.0+ or an OpenSSL build that provides:
  - `openssl ech`
  - `openssl s_client -ech_config_list`

If OpenSSL 4 is not the system `openssl`, pass it explicitly:

```bash
OPENSSL_BIN=/path/to/openssl ./test-ech.sh
```

## Quick Start

Run the full verification:

```bash
./test-ech.sh
```

The script performs these checks:

1. Generate a local certificate for both names.
2. Generate an ECH PEM file with `openssl ech -public_name public.example.test`.
3. Start the `caoweida2004/nginx-http3:latest` container.
4. Verify normal HTTPS to both names.
5. Send an ECH-enabled request with `openssl s_client -ech_config_list`.
6. Confirm the NGINX access log contains both `ECH:NOT_TRIED` and `ECH:SUCCESS:public.example.test hidden.example.test`.

## Manual Steps

Generate certificate and ECH files:

```bash
./generate-cert-and-ech.sh
```

Start NGINX:

```bash
docker compose up -d
```

Test without ECH:

```bash
curl --cacert ssl/cert.pem \
  --resolve hidden.example.test:443:127.0.0.1 \
  https://hidden.example.test/
```

Test with ECH:

```bash
ECH_CONFIG="$(cat ech/echconfig-list.b64)"
printf 'GET / HTTP/1.0\r\nHost: hidden.example.test\r\nConnection: close\r\n\r\n' | \
  openssl s_client \
    -connect 127.0.0.1:443 \
    -servername hidden.example.test \
    -ech_config_list "${ECH_CONFIG}" \
    -CAfile ssl/cert.pem \
    -verify_hostname hidden.example.test \
    -ign_eof
```

Check the evidence in the access log:

```bash
docker compose exec nginx tail -50 /usr/local/nginx/logs/access.log
```

Expected log patterns:

```text
ECH:NOT_TRIED:- hidden.example.test
ECH:SUCCESS:public.example.test hidden.example.test
```

## DNS Publication

For a real deployment, publish the generated ECHConfigList in an HTTPS resource record for the hidden name:

```text
hidden.example.test. HTTPS 1 . ech=<base64 from ech/echconfig-list.b64>
```

The local test skips DNS by passing that base64 value directly to `openssl s_client -ech_config_list`.
