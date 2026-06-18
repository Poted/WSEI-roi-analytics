# WSEI ROI Analytics — Project Handover

## Thesis
"Projekt i implementacja hurtowni danych do atrybucji marketingowej i analizy ROI kanałów pozyskiwania klientów"
Student: Poted (Git user) | University: WSEI

## Stack
- PostgreSQL 16 (Docker, Alpine) — `roi_postgres` container
- dbt Core 1.11.11 + dbt-postgres 1.9.1 — transformations
- Metabase v0.50.21 (Docker, self-hosted) — dashboards at http://localhost:3000
- Python 3.11 + SQLAlchemy 2.x + pandas — data ingestion
- Two Kaggle datasets: Criteo clickstream + Olist e-commerce

## Architecture
```
data/ (raw CSV/TSV, gitignored)
  ↓ scripts/load_raw.py (COPY protocol)
PostgreSQL raw schema (raw.criteo_events, raw.olist_*)
  ↓ dbt
staging/  → stg_criteo__events (view), stg_olist__* (views)
dimensions/ → dim_date, dim_channel
facts/    → fact_touchpoints, fact_conversions, fact_orders, fact_leads
marts/    → mart_attribution_* (5 models), mart_channel_funnel, mart_channel_value, mart_channel_cpa, mart_attribution_comparison
```

## 5 Attribution Models
- `mart_attribution_last_click` — 100% credit to last touch
- `mart_attribution_first_click` — 100% credit to first touch
- `mart_attribution_linear` — equal split across all touches
- `mart_attribution_time_decay` — exponential decay, half-life 7 (relative units)
- `mart_attribution_position_based` — U-shape: 40% first, 40% last, 20% middle

## dbt Status (as of 2026-06-15)
12/21 models built successfully. `fact_touchpoints` fails with PostgreSQL I/O error.

### Built OK (12):
- All 6 staging views
- dim_date, dim_channel
- fact_orders (99,441 rows), fact_leads (8,000 rows)
- mart_channel_funnel (11 rows), mart_channel_value (11 rows)

### Blocked (9 — all depend on fact_touchpoints):
- `fact_touchpoints` → ERROR: `could not open file "base/16384/49211": I/O error`
- fact_conversions, mart_attribution_* (5 models), mart_channel_cpa, mart_attribution_comparison

### Root cause of I/O error:
Docker Desktop disk space exhaustion. `raw.criteo_events` has 16.4M rows. Creating
`fact_touchpoints` as a TABLE triggers a massive write. Docker VM disk fills up.

### Fix options:
1. **Increase Docker disk**: Docker Desktop → Settings → Resources → Disk image size (increase to 100GB+)
2. **Prune Docker**: `docker system prune` to free space, then retry
3. **Change materialization**: In `dbt/models/facts/fact_touchpoints.sql`, change
   `{{ config(materialized='table') }}` to `{{ config(materialized='incremental', unique_key='touchpoint_id') }}`
   and add `{% if is_incremental() %} where click_timestamp_rel > (select max(click_timestamp_rel) from {{ this }}) {% endif %}`

## Criteo Data Quirks (CRITICAL — do not change staging model without reading this)
- `timestamp` is RELATIVE seconds from dataset start (anonymised), NOT unix epoch
- `to_timestamp()` will produce 1970-01-01 dates — do not use it
- `click=0` = impression (94.8% of rows), `click=1` = actual click
- `click_pos` and `click_nb` = -1 for impressions (no journey data) → use `nullif(..., -1)`
- `conversion_id` and `conversion_timestamp` = -1 when no conversion → cast to null
- `cost` = 0 for impressions, actual spend for clicks
- fact_touchpoints filters `where is_click = 1` — impressions have no attribution meaning

## Olist Data Notes
- Only 380/842 closed leads match the sellers table (45%) — known data quality issue, documented in EDA
- All olist timestamps are real ISO 8601 dates (unlike Criteo)

## Security Rules (MANDATORY — do not violate)
- `.gitignore` uses `.env*` (not just `.env`) — no .env files of any kind in git
- No hardcoded passwords anywhere — use `:?` fail-fast in docker-compose
- Docker ports bound to `127.0.0.1` only (not 0.0.0.0)
- `dbt/profiles.yml` is gitignored — create locally with env_var() interpolation
- `DATABASE_URL` must fail loudly if missing (EnvironmentError in load_raw.py)

## Setup on New Machine

### 1. Prerequisites
- Docker Desktop (increase disk to 100GB+ in Settings → Resources)
- Python 3.11
- Git clone the repo

### 2. Create .env file (gitignored, create manually)
```
POSTGRES_DB=roi_analytics
POSTGRES_USER=analytics
POSTGRES_PASSWORD=<choose_strong_password>
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
DATABASE_URL=postgresql://analytics:<password>@localhost:5432/roi_analytics
```

### 3. Create dbt/profiles.yml (gitignored, create manually)
```yaml
roi_analytics:
  target: dev
  outputs:
    dev:
      type: postgres
      host: "{{ env_var('POSTGRES_HOST', 'localhost') }}"
      port: "{{ env_var('POSTGRES_PORT', '5432') | int }}"
      user: "{{ env_var('POSTGRES_USER') }}"
      password: "{{ env_var('POSTGRES_PASSWORD') }}"
      dbname: "{{ env_var('POSTGRES_DB') }}"
      schema: public
      threads: 4
      connect_timeout: 10
```

### 4. Install Python deps
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 5. First run
```powershell
make up          # starts PostgreSQL + Metabase
make download    # downloads Kaggle datasets (requires kaggle API key in ~/.kaggle/kaggle.json)
make load        # loads raw data via COPY (fast, ~5 min for 16.4M Criteo rows)
make dbt-deps    # installs dbt_utils package
make dbt-run     # builds all 21 models
make dbt-test    # runs 33 data tests
```

## Python Environment Notes
- On Windows: use `.venv\Scripts\Activate.ps1` before any `make` commands
- `make` must be run from within the activated venv, or use `python scripts/dbt_runner.py` directly
- `scripts/dbt_runner.py` is a wrapper that loads `.env` before running dbt (Windows Make doesn't propagate env vars well)

## dbt Notes
- `dbt-state` package should NOT be installed — it prompts for dbt Cloud login. Run `pip uninstall dbt-state -y` if present.
- dbt-postgres 1.9.1 with dbt-core 1.11.11 is a supported combination (bridged via dbt-adapters). The "out of date" warning is cosmetic.
- No dbt-postgres 1.11.x stable exists — 1.9.1 is the correct version to use.

## Docker Networking (Windows-specific)
- Docker Desktop on Windows routes host→container traffic through bridge network (172.19.0.1)
- `POSTGRES_HOST_AUTH_METHOD: scram-sha-256` in docker-compose.yml is required
- If you change docker-compose.yml auth settings, must run `docker compose down -v` to wipe and reinitialize the volume

## Kaggle Data Download
- Requires `~/.kaggle/kaggle.json` with your Kaggle API key
- Datasets: `criteo/criteo-uplift-prediction` + `olistbr/brazilian-ecommerce`
- Files go into `data/criteo/` and `data/olist/` (gitignored)

## File Structure
```
wsei-roi-analytics/
├── CLAUDE.md               ← you are here
├── docker-compose.yml
├── Makefile
├── requirements.txt
├── .gitignore
├── scripts/
│   ├── load_raw.py         ← PostgreSQL COPY ingestion
│   ├── dbt_runner.py       ← dbt wrapper that loads .env
│   └── download_data.py    ← Kaggle download
├── dbt/
│   ├── dbt_project.yml
│   ├── packages.yml        ← dbt_utils >=1.3.0
│   ├── profiles.yml        ← GITIGNORED, create locally
│   ├── models/
│   │   ├── staging/criteo/ → stg_criteo__events.sql
│   │   ├── staging/olist/  → stg_olist__*.sql (6 files)
│   │   ├── dimensions/     → dim_date.sql, dim_channel.sql
│   │   ├── facts/          → fact_touchpoints.sql, fact_conversions.sql, fact_orders.sql, fact_leads.sql
│   │   └── marts/          → mart_attribution_*.sql (5), mart_channel_*.sql (3), mart_attribution_comparison.sql
│   └── sources/
│       ├── criteo.yml
│       └── olist.yml
├── notebooks/
│   └── 01_eda.ipynb        ← EDA: Criteo quirks documented here
└── data/
    ├── criteo/             ← GITIGNORED (16.4M row TSV)
    └── olist/              ← GITIGNORED (9 CSV files)
```
