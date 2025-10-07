# Makefile for Inception project

# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/$(USER)/data

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
NC = \033[0m # No Color

all: build up

# Create necessary directories for volumes
setup:
	@echo "$(YELLOW)Creating data directories...$(NC)"
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p secrets
	@echo "$(GREEN)Setup complete!$(NC)"

# Build all containers
build: setup
	@echo "$(YELLOW)Building containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build
	@echo "$(GREEN)Build complete!$(NC)"

# Start all containers
up:
	@echo "$(YELLOW)Starting containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)Containers started!$(NC)"

# Stop all containers
down:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Containers stopped!$(NC)"

# Clean containers and images
clean: down
	@echo "$(YELLOW)Cleaning containers and images...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo "$(GREEN)Clean complete!$(NC)"

# Full clean including volumes data
fclean: clean
	@echo "$(RED)Removing all data...$(NC)"
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	@docker system prune -af --volumes
	@echo "$(GREEN)Full clean complete!$(NC)"

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
	@echo "$(GREEN)Inception Makefile Commands:$(NC)"
	@echo "  make setup  - Create necessary directories"
	@echo "  make build  - Build all Docker images"
	@echo "  make up     - Start all containers"
	@echo "  make down   - Stop all containers"
	@echo "  make clean  - Stop and remove containers/images"
	@echo "  make fclean - Full clean including data"
	@echo "  make re     - Rebuild everything from scratch"
	@echo "  make logs   - Show container logs"
	@echo "  make ps     - Show container status"

.PHONY: all build up down clean fclean re logs ps