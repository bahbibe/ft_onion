#!/bin/bash
set -eu

# Own Tor daemon, default SocksPort 9050, used to reach the server's
# .onion address exactly like a real Tor user would - never contacts
# the server container directly on the docker network.
tor &

tail -f /dev/null
