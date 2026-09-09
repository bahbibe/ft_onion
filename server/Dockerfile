FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    nginx \
    tor \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash onion

COPY nginx.conf /etc/nginx/nginx.conf
COPY torrc /etc/tor/torrc
COPY sshd_config /etc/ssh/sshd_config
COPY index.html /var/www/onion/index.html
COPY keys/id_ed25519.pub /tmp/onion_key.pub
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /home/onion/.ssh \
    && cat /tmp/onion_key.pub >> /home/onion/.ssh/authorized_keys \
    && rm /tmp/onion_key.pub \
    && chown -R onion:onion /home/onion/.ssh \
    && chmod 700 /home/onion/.ssh \
    && chmod 600 /home/onion/.ssh/authorized_keys \
    && chmod +x /usr/local/bin/entrypoint.sh

# Documentation only - does not publish anything to the host.
# Reachability is via the Tor hidden service (torrc), not this.
EXPOSE 80 4242

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
