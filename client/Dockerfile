FROM debian:stable-slim


RUN apt-get update && apt-get install -y \
    tor \
    wget \
    curl \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

