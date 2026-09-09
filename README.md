# ft_onion

A static webpage served entirely as a Tor hidden service, plus SSH
access, both reachable only through Tor - no host ports are ever
published, no firewall rules are set.

## Architecture

Two containers:

- **`server/`** - one container running three processes: `nginx`
  (serves `index.html` on `127.0.0.1:80`), `sshd` (listens on
  `127.0.0.1:4242`, key-only auth), and `tor` (publishes the hidden
  service, mapping its virtual ports 80 and 4242 to those two loopback
  services - see `server/torrc`). All three are started and supervised
  by `server/entrypoint.sh`, a small bash script (`trap` + background +
  `wait`). A process manager like supervisord was deliberately left
  out: the subject asks for four config files, not extra tooling, and
  nothing here needs auto-restart policies.
- **`client/`** - a separate container with its own Tor daemon (SOCKS
  proxy on port 9050) plus `torsocks`/`curl`/`ssh`. It only ever
  reaches the server through the `.onion` address via its own Tor
  proxy, exactly like a real Tor user would - never over the docker
  network directly. This is the only way to actually prove the hidden
  service works as a hidden service.

Both containers are built `FROM debian:stable-slim` for consistency.

## Why no ports are "open"

`docker-compose.yml` has no `ports:` keys, and nothing runs `iptables`
or similar. The `EXPOSE 80 4242` line in `server/Dockerfile` is
documentation only - it does not publish anything to the host. The
only way into the server is through the Tor hidden service.

## Persistence

The hidden service's directory (`/var/lib/tor/hidden_service`, holding
the private key and the generated `hostname`) is a named Docker volume
(`hidden_service`), not a bind mount - this avoids host UID/GID
mismatches against the `debian-tor` user Tor runs as in this container
and requires that directory to be owned by (`chown 700
debian-tor:debian-tor`, done at container start by `entrypoint.sh`).
As long as the volume isn't removed, the
`.onion` address stays the same across rebuilds.

## SSH

Auth is key-only from the start (`PasswordAuthentication no` in
`server/sshd_config`), for a single user, `onion`. `make keys`
generates a local ed25519 keypair at `server/keys/` (gitignored, never
committed) whose public half is baked into the image's
`authorized_keys` at build time.

## Usage

```sh
make up      # generates the SSH keypair if needed, builds, starts both containers
make onion   # prints the current .onion address
make logs    # follow both containers' logs
make down    # stop (keeps the volume, .onion address survives)
make fclean  # stop and remove volumes/images (new .onion address next build)
```

## Verifying the hidden service

```sh
# no host ports published:
docker compose ps

# from the client, over the client's own Tor SOCKS proxy (port 9050):
docker compose exec client bash
curl --socks5-hostname 127.0.0.1:9050 http://<address>.onion/
# (curl refuses to resolve .onion itself - RFC 7686 - so the SOCKS
# proxy must do the remote lookup; --socks5-hostname does that)

# copy the test key into the client to try SSH the same way:
docker compose cp server/keys/id_ed25519 client:/tmp/id_ed25519
docker compose exec client torsocks ssh -i /tmp/id_ed25519 -p 4242 onion@<address>.onion
```

## Bonus

Started only after the mandatory part above was fully verified working.

- **SSH fortification** (`server/sshd_config`) - on top of the mandatory
  key-only baseline: single `ed25519` host key (RSA dropped), explicit
  modern-only `KexAlgorithms`/`Ciphers`/`MACs` allowlists, `MaxAuthTries
  3`, `LoginGraceTime 20`, `ClientAlive*` to drop dead sessions, and
  `DisableForwarding yes` plus explicit `X11Forwarding`/
  `AllowAgentForwarding`/`AllowTcpForwarding`/`PermitTunnel no` - this
  service has no legitimate use for SSH forwarding.
- **Interactive application** (`server/index.html`) - the same single
  static file now doubles as a circuit visualizer: an inline
  canvas/JS animation of a Tor circuit (you → guard → middle →
  rendezvous → this service), showing one encryption layer peeled per
  hop and what each relay can and can't see. Deliberately zero external
  dependencies (no CDN fetch) - still exactly one static `index.html`,
  still served by nginx alone, satisfying "more impressive than a static
  page" without touching the "Nginx only, no other framework" mandatory
  rule.
