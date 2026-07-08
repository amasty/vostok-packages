#!/bin/bash
set -euo pipefail

TEMPLATE="$(dirname "$0")/template"
CURRENT=$(grep '^version=' "${TEMPLATE}" | cut -d= -f2)

TMPDIR=$(mktemp -d)
cd "$TMPDIR"
curl -sL -o linux64 "https://dl.pstmn.io/download/latest/linux64"

bsdtar -xf linux64 2>/dev/null || true

PKG_JSON=$(find . -name 'package.json' -path '*/app/package.json' -print -quit)
if [ -z "$PKG_JSON" ]; then
    echo "ERROR: app/package.json not found in the archive" >&2
    echo "Archive contents:"
    bsdtar -tf linux64 2>/dev/null | head -20
    exit 1
fi

VERSION=$(python3 -c "import json; print(json.load(open('$PKG_JSON'))['version'])")

cd - >/dev/null
rm -rf "$TMPDIR"

if [ "${CURRENT}" = "${VERSION}" ]; then
    echo "postman: ${CURRENT} — already up to date"
    exit 0
fi

echo "postman: ${CURRENT} → ${VERSION}"

CHECKSUM=$(curl -L -# "https://dl.pstmn.io/download/latest/linux64" | sha256sum | cut -d' ' -f1)

sed -i "s/^version=.*/version=${VERSION}/" "${TEMPLATE}"
sed -i "s/^checksum=.*/checksum=${CHECKSUM}/" "${TEMPLATE}"
sed -i "s/^revision=.*/revision=1/" "${TEMPLATE}"

echo "Done: ${VERSION} (${CHECKSUM:0:16}...)"