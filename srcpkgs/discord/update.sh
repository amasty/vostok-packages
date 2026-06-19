#!/bin/bash
set -euo pipefail

TEMPLATE="$(dirname "$0")/template"
CURRENT=$(grep '^version=' "${TEMPLATE}" | cut -d= -f2)

API_URL="https://discord.com/api/download?platform=linux&format=deb"
LATEST_URL=$(curl -sI "$API_URL" | grep -i '^location:' | awk '{print $2}' | tr -d '\r')
LATEST_VERSION=$(echo "$LATEST_URL" | grep -oP 'discord-\K[0-9.]+(?=\.deb)')

if [ "${CURRENT}" = "${LATEST_VERSION}" ]; then
    echo "discord: ${CURRENT} — already up to date"
    exit 0
fi

echo "discord: ${CURRENT} → ${LATEST_VERSION}"

DEB_URL="https://stable.dl2.discordapp.net/apps/linux/${LATEST_VERSION}/discord-${LATEST_VERSION}.deb"
echo "URL: ${DEB_URL}"

if ! curl --head --silent --fail "${DEB_URL}" > /dev/null; then
    echo "ERROR: Deb package not found at ${DEB_URL}" >&2
    exit 1
fi

CHECKSUM=$(curl -L -# "${DEB_URL}" | sha256sum | cut -d' ' -f1)

sed -i "s/^version=.*/version=${LATEST_VERSION}/" "${TEMPLATE}"
sed -i "s/^checksum=.*/checksum=${CHECKSUM}/" "${TEMPLATE}"
sed -i "s/^revision=.*/revision=1/" "${TEMPLATE}"

echo "Done: ${LATEST_VERSION} (${CHECKSUM:0:16}...)"