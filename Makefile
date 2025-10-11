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
# added @chmod -R u+w $(DATA_PATH) 2>/dev/null || true
# added @chmod -R u+w secrets 2>/dev/null || true
setup:
	@echo -e "$(YELLOW)Creating data directories...$(NC)"
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p secrets
	@chmod -R u+w $(DATA_PATH) 2>/dev/null || true
	@chmod -R u+w secrets 2>/dev/null || true
	@echo -e "$(GREEN)Setup complete!$(NC)"

# Build all containers
build: setup
	@echo -e "$(YELLOW)Building containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build
	@echo -e "$(GREEN)Build complete!$(NC)"

# Start all containers
up:
	@echo -e "$(YELLOW)Starting containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo -e "$(GREEN)Containers started!$(NC)"

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
	@chown -R $(USER):$(USER) $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress 2>/dev/null || true
	@docker system prune -af --volumes > /dev/null 2>&1 || true
	@echo -e "$(GREEN)Full clean complete!$(NC)"

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

.PHONY: all build up down clean fclean re logs ps
