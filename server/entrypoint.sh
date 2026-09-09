#!/bin/bash
set -eu

HS_DIR=/var/lib/tor/hidden_service

mkdir -p "$HS_DIR"
# tor runs as debian-tor (its normal package user, matching the
# already debian-tor-owned /var/lib/tor DataDirectory) - a fresh
# volume mount defaults to root, so fix ownership every start.
chown -R debian-tor:debian-tor "$HS_DIR"
chmod 700 "$HS_DIR"

ssh-keygen -A
mkdir -p /run/sshd

/usr/sbin/sshd -D &
SSHD_PID=$!

nginx -g "daemon off;" &
NGINX_PID=$!

su -s /bin/sh -c "tor -f /etc/tor/torrc" debian-tor &
TOR_PID=$!

term() {
    kill -TERM "$SSHD_PID" "$NGINX_PID" "$TOR_PID" 2>/dev/null || true
}
trap term SIGTERM SIGINT

wait -n "$SSHD_PID" "$NGINX_PID" "$TOR_PID"
term
wait
