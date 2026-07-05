start-dev:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

stop-dev:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml down

start-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

stop-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml down

start-backup:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.backup.yml up -d

stop-backup:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.backup.yml down

.PHONY: start-dev stop-dev start-prod stop-prod start-backup stop-backup
