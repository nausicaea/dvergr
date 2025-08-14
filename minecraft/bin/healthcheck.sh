#!/bin/sh

SERVER_ADDRESS='127.0.0.1'
SERVER_PORT=$(awk -F= '/server-port/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2 }' /etc/minecraft/server/server.properties 2>/dev/null || printf '25565')
PROTOCOL_VERSION='8106'
SERVER_ADDRESS_LEN=$(printf '%s' "$SERVER_ADDRESS" | wc -c | awk '{ print $1 }')
PACKET_LEN=$(printf '%02x' "$(( 1 + 2 + 1 + $SERVER_ADDRESS_LEN + 2 + 1 ))")

HANDSHAKE_PACKET="${PACKET_LEN}00${PROTOCOL_VERSION}$(printf '%02x' "${SERVER_ADDRESS_LEN}")$(printf '127.0.0.1' | xxd -p)$(printf '%04x' "$SERVER_PORT")01"
STATUS_PACKET="0100"

RESPONSE=$(printf '%s%s' "$HANDSHAKE_PACKET" "$STATUS_PACKET" | xxd -r -p | nc -w 2 -n "$SERVER_ADDRESS" "$SERVER_PORT" | tail -c +6)
RESPONSE_LEN=$(printf '%s' $RESPONSE | wc -c | awk '{ print $1 }')

if [ "$RESPONSE_LEN" -gt 0 ]; then
    printf '%s\n' "$RESPONSE"
    exit 0
else
    printf 'empty response from server\n'
    exit 1
fi
