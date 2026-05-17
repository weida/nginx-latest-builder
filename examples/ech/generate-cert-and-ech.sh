#!/usr/bin/env bash
set -euo pipefail

PUBLIC_NAME="${PUBLIC_NAME:-public.example.test}"
HIDDEN_NAME="${HIDDEN_NAME:-hidden.example.test}"
OPENSSL_BIN="${OPENSSL_BIN:-openssl}"

cd "$(dirname "$0")"
mkdir -p ssl ech

if ! "$OPENSSL_BIN" list -commands 2>/dev/null | tr ' ' '\n' | grep -qx ech; then
    echo "ERROR: $OPENSSL_BIN does not provide the 'ech' command."
    echo "Use OpenSSL 4.0+ or an OpenSSL build with ECH support, for example:"
    echo "  OPENSSL_BIN=/path/to/openssl ./generate-cert-and-ech.sh"
    exit 1
fi

echo "Generating self-signed certificate for ${PUBLIC_NAME} and ${HIDDEN_NAME}"
"$OPENSSL_BIN" req -x509 -nodes -days 365 \
    -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/CN=${PUBLIC_NAME}" \
    -addext "subjectAltName=DNS:${PUBLIC_NAME},DNS:${HIDDEN_NAME}"

echo "Generating ECH key pair for public name ${PUBLIC_NAME}"
"$OPENSSL_BIN" ech \
    -public_name "${PUBLIC_NAME}" \
    -out "ech/${PUBLIC_NAME}.pem.ech"

awk '
    /BEGIN .*ECH/ { inside = 1; next }
    /END .*ECH/ { inside = 0 }
    inside { gsub(/[[:space:]]/, ""); printf "%s", $0 }
    END { printf "\n" }
' "ech/${PUBLIC_NAME}.pem.ech" > ech/echconfig-list.b64

if [ ! -s ech/echconfig-list.b64 ]; then
    echo "ERROR: failed to extract base64 ECHConfigList from ech/${PUBLIC_NAME}.pem.ech"
    exit 1
fi

echo ""
echo "Generated files:"
echo "  ssl/cert.pem"
echo "  ssl/key.pem"
echo "  ech/${PUBLIC_NAME}.pem.ech"
echo "  ech/echconfig-list.b64"
echo ""
echo "Local HTTPS RR example for DNS publication:"
echo "  ${HIDDEN_NAME}. HTTPS 1 . ech=$(cat ech/echconfig-list.b64)"
