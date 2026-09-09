COMPOSE  = docker compose
KEY_DIR  = server/keys
KEY_FILE = $(KEY_DIR)/id_ed25519

.PHONY: all keys build up down re logs onion fclean

all: up

# Generates the SSH test keypair used to authorize the "onion" user
# in the server image. Never committed - see .gitignore.
keys:
	@mkdir -p $(KEY_DIR)
	@if [ ! -f $(KEY_FILE) ]; then \
		ssh-keygen -t ed25519 -N "" -f $(KEY_FILE) -C onion-test-key; \
	fi

build: keys
	$(COMPOSE) build

up: keys
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

re: down up

logs:
	$(COMPOSE) logs -f

# Prints the current .onion address.
onion:
	$(COMPOSE) exec server cat /var/lib/tor/hidden_service/hostname

# Destroys the hidden-service volume too: next build gets a new
# .onion identity.
fclean:
	$(COMPOSE) down -v --rmi local
