# Makefile for Inception project

# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/$(USER)/data
SECRETS_DIR = secrets

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
NC = \033[0m # No Color

all: build up help

# Create necessary directories for volumes
setup: setup-secrets
	@echo -e "$(YELLOW)Creating data directories...$(NC)"
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@chmod -R u+w $(DATA_PATH) 2>/dev/null || true
	@chmod -R u+w secrets 2>/dev/null || true
	@echo -e "$(GREEN)Setup complete!$(NC)"

# Setup secrets with user input
setup-secrets:
	@if [ -d $(SECRETS_DIR) ]; \
		then \
		echo -e "$(RED)⚠️  Secrets already exist in ./$(SECRETS_DIR)/$(NC)"; \
		echo -e "$(YELLOW)Please remove the directory to recreate: rm -rf $(SECRETS_DIR)$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(YELLOW)=== Inception Secrets Setup ===$(NC)"
	@mkdir -p $(SECRETS_DIR)
	@chmod 700 $(SECRETS_DIR)
	@echo ""
	@./scripts/setup_secrets.sh
	@chmod 600 $(SECRETS_DIR)/*
	@echo ""
	@echo -e "$(GREEN)✅ Secrets created successfully!$(NC)"
	@echo -e "$(YELLOW)⚠️  Keep ./$(SECRETS_DIR)/ safe and never commit to Git!$(NC)"

# Build all containers
build: setup
	@echo -e "$(YELLOW)Building containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build
	@echo -e "$(GREEN)Build complete!$(NC)"

# Start all containers
up:
	@echo -e "$(YELLOW)Starting containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d

# Stop all containers
down:
	@echo -e "$(YELLOW)Stopping containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo -e "$(GREEN)Containers stopped!$(NC)"

# Clean containers and images
clean: down
	@echo -e "$(YELLOW)Cleaning containers and images...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo -e "$(GREEN)Clean complete!$(NC)"

# Full clean including volumes data
fclean: clean
	@echo -e "$(RED)Removing all data...$(NC)"
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	@chmod -R u+w $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress 2>/dev/null || true
	@rm -rf $(DATA_PATH)/mariadb/* 2>/dev/null || true
	@rm -rf $(DATA_PATH)/wordpress/* 2>/dev/null || true
	@rm -rf $(SECRETS_DIR)
	@chown -R $(USER):$(USER) $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress 2>/dev/null || true
	@docker system prune -af --volumes > /dev/null 2>&1 || true
	@echo -e "$(GREEN)Full clean complete!$(NC)"
	docker ps
	@if [ `docker ps | wc -l` -eq 1 ]; then echo -e "$(GREEN)No dockers available!$(NC)"; \
	else echo -e "$(RED)Some containers still running! :-($(NC)"; \
	fi
	docker volume ls
	@if [ `docker volume ls | wc -l` -eq 1 ]; then echo -e "$(GREEN)No volumes available!$(NC)"; \
	else echo -e "$(RED)Some volumes remain! :-($(NC)"; \
	fi
	docker image ls
	@if [ `docker image ls | wc -l` -eq 1 ]; then echo -e "$(GREEN)All images removed!$(NC)"; \
	else echo -e "$(RED)Some images remain! :-($(NC)"; \
	fi
	docker network ls
	@if [ `docker network ls | wc -l` -eq 4 ]; then echo -e "$(GREEN)All project networks removed!$(NC)"; \
	else echo -e "$(RED)Network remain! :-($(NC)"; \
	fi

# Rebuild everything
re: fclean all

# Show logs
logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

# Show container status
ps:
	@docker-compose -f $(COMPOSE_FILE) ps

# Show help
help:
	@echo -e "$(GREEN)Inception Makefile Commands:$(NC)"
	@echo "  make setup  - Create necessary directories"
	@echo "  make build  - Build all Docker images"
	@echo "  make up     - Start all containers"
	@echo "  make down   - Stop all containers"
	@echo "  make clean  - Stop and remove containers/images"
	@echo "  make fclean - Full clean including data"
	@echo "  make re     - Rebuild everything from scratch"
	@echo "  make logs   - Show container logs"
	@echo "  make ps     - Show container status"

.PHONY: all build up down clean fclean re logs ps setup-secrets
