.PHONY: up down logs download load dbt-deps dbt-run dbt-test dbt-docs setup

# ---------- Infrastructure ----------
up:
	docker compose up -d
	@echo "PostgreSQL: localhost:5432 | Metabase: http://localhost:3000"

down:
	docker compose down

logs:
	docker compose logs -f

# ---------- Data ----------
download:
	python scripts/download_data.py

load:
	python scripts/load_raw.py

# ---------- dbt ----------
dbt-deps:
	cd dbt && dbt deps

dbt-run:
	cd dbt && dbt run

dbt-test:
	cd dbt && dbt test

dbt-docs:
	cd dbt && dbt docs generate && dbt docs serve --port 8080

# ---------- Full setup (first time) ----------
setup: up
	@echo "Waiting for PostgreSQL..."
	@sleep 5
	$(MAKE) download
	$(MAKE) load
	$(MAKE) dbt-deps
	$(MAKE) dbt-run
	$(MAKE) dbt-test
	@echo "Setup complete. Metabase: http://localhost:3000"
