#!/bin/bash

set -euo pipefail

readonly IDENTITY_NAME="${LOCAL_APP_SIGNING_IDENTITY:-Local Mac App Code Signing}"
readonly LOGIN_KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: required command not found: $1" >&2
        exit 1
    fi
}

has_signing_identity() {
    security find-identity -v -p codesigning "$LOGIN_KEYCHAIN" 2>/dev/null \
        | grep -F "\"${IDENTITY_NAME}\"" >/dev/null
}

require_command openssl
require_command security

if [[ ! -f "$LOGIN_KEYCHAIN" ]]; then
    echo "error: login keychain not found: $LOGIN_KEYCHAIN" >&2
    exit 1
fi

if has_signing_identity; then
    echo "Signing identity already available: $IDENTITY_NAME"
    exit 0
fi

temporary_directory="$(mktemp -d "${TMPDIR%/}/local-app-signing.XXXXXX")"
chmod 700 "$temporary_directory"

cleanup() {
    local temporary_file
    for temporary_file in \
        "$temporary_directory/private-key.pem" \
        "$temporary_directory/certificate.pem" \
        "$temporary_directory/identity.p12"; do
        if [[ -f "$temporary_file" ]]; then
            rm -P "$temporary_file"
        fi
    done
    rmdir "$temporary_directory" 2>/dev/null || true
}
trap cleanup EXIT

openssl req \
    -x509 \
    -newkey rsa:2048 \
    -sha256 \
    -days 3650 \
    -nodes \
    -subj "/CN=${IDENTITY_NAME}/O=Local Development" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -addext "subjectKeyIdentifier=hash" \
    -addext "authorityKeyIdentifier=keyid,issuer" \
    -keyout "$temporary_directory/private-key.pem" \
    -out "$temporary_directory/certificate.pem" \
    >/dev/null 2>&1

p12_password="$(openssl rand -hex 32)"
openssl pkcs12 \
    -export \
    -legacy \
    -name "$IDENTITY_NAME" \
    -inkey "$temporary_directory/private-key.pem" \
    -in "$temporary_directory/certificate.pem" \
    -out "$temporary_directory/identity.p12" \
    -passout "pass:${p12_password}" \
    >/dev/null 2>&1

security import "$temporary_directory/identity.p12" \
    -k "$LOGIN_KEYCHAIN" \
    -P "$p12_password" \
    -T /usr/bin/codesign \
    -T /usr/bin/security \
    >/dev/null

security add-trusted-cert \
    -d \
    -r trustRoot \
    -p codeSign \
    -k "$LOGIN_KEYCHAIN" \
    "$temporary_directory/certificate.pem"

if ! has_signing_identity; then
    echo "error: imported certificate is not a valid code-signing identity" >&2
    exit 1
fi

echo "Created signing identity: $IDENTITY_NAME"
