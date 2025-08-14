#!/bin/sh

MINECRAFT_SERVER_PORT=$(awk -F= '/server-port/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2 }' /etc/minecraft/server/server.properties)

PROTOCOL_VERSION=$(printf '8106' | xxd -r -p)
SERVER_ADDRESS="127.0.0.1"
SERVER_ADDRESS_LEN=$(printf '%02x' "$(printf '%s' "$SERVER_ADDRESS" | wc -c | awk '{ print $1 }')" | xxd -r -p)
SERVER_PORT=$(printf '%02x' "$MINECRAFT_SERVER_PORT" | xxd -r -p)
INTENT=$(printf '01' | xxd -r -p)
TIMESTAMP=$(printf '%016x' "$(( $(date +%s) * 1000 ))" | xxd -r -p)

HANDSHAKE_PACKET="\x10\x00$PROTOCOL_VERSION$SERVER_ADDRESS_LEN$SERVER_ADDRESS$SERVER_PORT$INTENT"
STATUS_PACKET="\x01\x00"
PING_PACKET="\x09\x01$TIMESTAMP"

SERVER_RESPONSE=$(printf '%s%s' "$HANDSHAKE_PACKET" "$STATUS_PACKET" | nc -w 2 -n 127.0.0.1 "$MINECRAFT_SERVER_PORT")

echo "Response: $SERVER_RESPONSE"
exit 1
