.PHONY: help build up down logs clean restart migrate seed secret

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Docker images
	docker-compose build

up: ## Start all services
	docker-compose up -d

down: ## Stop all services
	docker-compose down

logs: ## View logs from all services
	docker-compose logs -f

logs-web: ## View logs from web service only
	docker-compose logs -f web

logs-db: ## View logs from database service only
	docker-compose logs -f db

clean: ## Stop containers and remove volumes
	docker-compose down -v
	docker system prune -f

restart: ## Restart all services
	docker-compose restart

migrate: ## Run database migrations
	docker-compose exec web /app/bin/migrate

seed: ## Run database seeds (if available)
	docker-compose exec web /app/bin/url_shortener eval "Mix.Tasks.Run.run(['priv/repo/seeds.exs'])"

secret: ## Generate a new secret key base
	@echo "Generated SECRET_KEY_BASE:"
	@openssl rand -base64 32

shell-web: ## Get shell access to web container
	docker-compose exec web /bin/bash

shell-db: ## Get shell access to database
	docker-compose exec db psql -U postgres url_shortener_dev

build-prod: ## Build and start production environment
	docker-compose up --build -d