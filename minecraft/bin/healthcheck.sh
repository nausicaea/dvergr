#!/bin/sh

MINECRAFT_SERVER_RESPONSE=$(printf '\xfe' | nc -w 2 -n 127.0.0.1 30000)
RESPONSE_LENGTH=$(printf '%s' "$MINECRAFT_SERVER_RESPONSE" | wc -c)

printf '%s' "$MINECRAFT_SERVER_RESPONSE"
exec test "$RESPONSE_LENGTH" -gt 0
