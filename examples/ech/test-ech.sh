#!/usr/bin/env bash
set -euo pipefail

PUBLIC_NAME="${PUBLIC_NAME:-public.example.test}"
HIDDEN_NAME="${HIDDEN_NAME:-hidden.example.test}"
OPENSSL_BIN="${OPENSSL_BIN:-openssl}"

cd "$(dirname "$0")"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
else
    echo "ERROR: Docker Compose is required for the ECH example test."
    exit 1
fi

if ! "$OPENSSL_BIN" list -commands 2>/dev/null | tr ' ' '\n' | grep -qx ech; then
    echo "ERROR: $OPENSSL_BIN does not provide the 'ech' command."
    echo "Use OpenSSL 4.0+ or an OpenSSL build with ECH support:"
    echo "  OPENSSL_BIN=/path/to/openssl ./test-ech.sh"
    exit 1
fi

if ! "$OPENSSL_BIN" s_client -help 2>&1 | grep -q -- "-ech_config_list"; then
    echo "ERROR: $OPENSSL_BIN s_client does not support -ech_config_list."
    exit 1
fi

./generate-cert-and-ech.sh

"${COMPOSE[@]}" up -d

cleanup() {
    "${COMPOSE[@]}" logs --tail=80 nginx || true
}
trap cleanup ERR

echo "Waiting for nginx to accept HTTPS traffic"
for _ in $(seq 1 30); do
    if curl -fsS --cacert ssl/cert.pem \
        --resolve "${PUBLIC_NAME}:443:127.0.0.1" \
        "https://${PUBLIC_NAME}/" >/tmp/ech-public.out 2>/tmp/ech-public.err; then
        break
    fi
    sleep 1
done

if ! grep -q "ECH public cover site" /tmp/ech-public.out; then
    echo "ERROR: public HTTPS check failed."
    cat /tmp/ech-public.err
    exit 1
fi

curl -fsS --cacert ssl/cert.pem \
    --resolve "${HIDDEN_NAME}:443:127.0.0.1" \
    "https://${HIDDEN_NAME}/" >/tmp/ech-hidden-no-ech.out

if ! grep -q "ECH hidden service" /tmp/ech-hidden-no-ech.out; then
    echo "ERROR: hidden HTTPS check without ECH failed."
    exit 1
fi

ECH_CONFIG="$(cat ech/echconfig-list.b64)"
printf 'GET / HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n' "${HIDDEN_NAME}" | \
    "$OPENSSL_BIN" s_client \
        -connect 127.0.0.1:443 \
        -servername "${HIDDEN_NAME}" \
        -ech_config_list "${ECH_CONFIG}" \
        -CAfile ssl/cert.pem \
        -verify_hostname "${HIDDEN_NAME}" \
        -ign_eof > /tmp/ech-s_client.out 2>&1

if ! grep -q "ECH hidden service" /tmp/ech-s_client.out; then
    echo "ERROR: ECH s_client request did not reach the hidden service."
    cat /tmp/ech-s_client.out
    exit 1
fi

"${COMPOSE[@]}" exec -T nginx sh -c 'tail -200 /usr/local/nginx/logs/access.log' > /tmp/ech-access.log

if ! grep -q "ECH:NOT_TRIED" /tmp/ech-access.log; then
    echo "ERROR: access log did not record the non-ECH control request."
    cat /tmp/ech-access.log
    exit 1
fi

if ! grep -q "ECH:SUCCESS:${PUBLIC_NAME} ${HIDDEN_NAME}" /tmp/ech-access.log; then
    echo "ERROR: access log did not record a successful ECH request."
    cat /tmp/ech-access.log
    exit 1
fi

echo "ECH verification passed:"
echo "  normal HTTPS request logged as ECH:NOT_TRIED"
echo "  ECH request reached ${HIDDEN_NAME} and logged ECH:SUCCESS:${PUBLIC_NAME} ${HIDDEN_NAME}"
