# WSEI ROI Analytics — Hurtownia Danych do Atrybucji Marketingowej

Projekt zaliczeniowy dla przedmiotu **Profesjonalna Aplikacja do Analizy Danych** (WSEI).  
Temat: *Projekt i implementacja hurtowni danych do atrybucji marketingowej i analizy ROI kanałów pozyskiwania klientów.*

---

## Cel projektu

Zbudowanie end-to-end hurtowni danych, która:

- Integruje dwa źródła marketingowe (clickstream + CRM/e-commerce)
- Implementuje **5 modeli atrybucji**: last-click, first-click, linear, time-decay, position-based (U-shape)
- Wylicza metryki ROI: CPA, CAC, GMV, funnel conversion rate per channel
- Udostępnia dashboardy w Metabase

---

## Stack technologiczny

| Warstwa | Technologia |
|---|---|
| Baza danych | PostgreSQL 16 (Docker) |
| Transformacje | dbt Core 1.7 |
| Wizualizacja | Metabase v0.50 |
| Orkiestracja | Make (Makefile) |
| Ingestia danych | Python + pandas + SQLAlchemy |
| Konteneryzacja | Docker Compose |

---

## Źródła danych

### 1. Criteo Attribution Modeling for Bidding
- **Kaggle**: `sharatsachin/criteo-attribution-modeling`
- ~16 mln zdarzeń kliknięć (clickstream)
- Kolumny: `uid`, `timestamp`, `campaign`, `click_pos`, `click_nb`, `cost`, `cpo`, `conversion`, `cat1-9`
- Służy do: multi-touch attribution, CPA per campaign, journey analysis

### 2. Olist Brazilian E-Commerce + Marketing Funnel
- **Kaggle**: `olistbr/brazilian-ecommerce` + `olistbr/marketing-funnel-olist`
- ~100k zamówień, ~8k MQL z nazwanymi kanałami pozyskania
- Służy do: funnel analysis per channel, revenue pipeline, GMV per acquisition channel

---

## Architektura

```
Kaggle CSV/TSV
     │
     ▼
[raw schema]          ← surowe dane, bez transformacji
     │
     ▼
[staging schema]      ← cast typów, rename kolumn, filtrowanie nullów
     │
     ▼
[dimensions / facts]  ← model gwiazdkowy (star schema)
     │
     ▼
[marts schema]        ← modele analityczne, atrybucja, ROI
     │
     ▼
Metabase Dashboards
```

### Warstwy dbt

```
dbt/models/
├── staging/
│   ├── criteo/          stg_criteo__events
│   └── olist/           stg_olist__leads_qualified, leads_closed, orders,
│                        order_payments, order_items
├── dimensions/
│   ├── dim_date         kalendarz 2016-2019
│   └── dim_channel      kanały pozyskania z etykietami i typami
├── facts/
│   ├── fact_touchpoints  punkty styku (Criteo)
│   ├── fact_conversions  konwersje z podróży użytkownika (Criteo)
│   ├── fact_orders       zamówienia + revenue (Olist)
│   └── fact_leads        leady + status zamknięcia (Olist)
└── marts/
    ├── attribution/
    │   ├── mart_attribution_last_click
    │   ├── mart_attribution_first_click
    │   ├── mart_attribution_linear
    │   ├── mart_attribution_time_decay   (half-life = 7 pozycji)
    │   ├── mart_attribution_position_based  (U-shape 40/20/40)
    │   └── mart_attribution_comparison   (wszystkie modele side-by-side)
    └── roi/
        ├── mart_channel_funnel   (leads → deals, conversion rate per channel)
        ├── mart_channel_cpa      (CPA last-click i first-click per campaign)
        └── mart_channel_value    (GMV + declared revenue per channel)
```

---

## Szybki start

### Wymagania

- Docker Desktop
- Python 3.10+
- Konto Kaggle z wygenerowanym API key

### 1. Konfiguracja zmiennych środowiskowych

```bash
cp .env.example .env
# Uzupełnij KAGGLE_USERNAME i KAGGLE_KEY w pliku .env
```

### 2. Uruchomienie całego pipeline'u

```bash
make setup
```

Polecenie wykonuje kolejno: `up` → `download` → `load` → `dbt-deps` → `dbt-run` → `dbt-test`.

### 3. Poszczególne kroki ręcznie

```bash
make up           # Uruchamia PostgreSQL + Metabase w Dockerze
make download     # Pobiera dane z Kaggle do data/criteo/ i data/olist/
make load         # Ładuje CSV/TSV do schematu raw w PostgreSQL
make dbt-deps     # Instaluje pakiety dbt (dbt_utils)
make dbt-run      # Buduje wszystkie modele
make dbt-test     # Uruchamia testy dbt
make dbt-docs     # Generuje i serwuje dokumentację dbt (port 8080)
```

### 4. Dostęp do narzędzi

| Narzędzie | URL | Domyślne dane |
|---|---|---|
| Metabase | http://localhost:3000 | konfiguracja przy pierwszym uruchomieniu |
| PostgreSQL | localhost:5432 | roi_analytics / roi_password |
| dbt docs | http://localhost:8080 | — |

---

## Konfiguracja dbt

Skopiuj przykładowy plik profilu:

```bash
cp dbt/profiles.yml.example ~/.dbt/profiles.yml
```

Lub ustaw zmienne środowiskowe zgodnie z `.env.example`.

---

## Modele atrybucji — opis

| Model | Logika |
|---|---|
| **Last-click** | 100% kredytu dla ostatniego touchpointu w journey |
| **First-click** | 100% kredytu dla pierwszego touchpointu |
| **Linear** | Równy podział kredytu między wszystkie touchpointy |
| **Time-decay** | Wyższy kredyt dla touchpointów bliżej konwersji; half-life = 7 pozycji |
| **Position-based** | First=40%, Last=40%, Middle=20% podzielone równo |

Wszystkie modele są porównywane w `mart_attribution_comparison` — jeden wiersz per (campaign, model).

---

## Schemat bazy danych

```
raw.*          — tabele ładowane bezpośrednio przez load_raw.py
staging.*      — widoki dbt (views)
dimensions.*   — tabele dbt: dim_date, dim_channel
facts.*        — tabele dbt: fact_touchpoints, fact_conversions, fact_orders, fact_leads
marts.*        — tabele dbt: modele atrybucji i ROI
```

---

## Struktura repozytorium

```
wsei-roi-analytics/
├── data/
│   ├── criteo/          # dane Criteo (gitignored, pobierane przez make download)
│   └── olist/           # dane Olist (gitignored)
├── dbt/
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── profiles.yml.example
│   └── models/          # patrz sekcja Architektura powyżej
├── notebooks/           # Jupyter EDA (opcjonalne)
├── scripts/
│   ├── init_db.sql      # tworzy schematy w PostgreSQL
│   ├── download_data.py # pobieranie z Kaggle
│   └── load_raw.py      # ingestia CSV → raw schema
├── docker-compose.yml
├── Makefile
├── requirements.txt
├── .env.example
└── .gitignore
```

---

## Autor

Projekt realizowany w ramach przedmiotu *Profesjonalna Aplikacja do Analizy Danych*, WSEI.
