.PHONY: up down logs download load dbt-deps dbt-run dbt-test dbt-docs setup

DBT = python scripts/dbt_runner.py

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
	$(DBT) deps

dbt-run:
	$(DBT) run

dbt-test:
	$(DBT) test

dbt-docs:
	$(DBT) docs generate && $(DBT) docs serve --port 8080

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
