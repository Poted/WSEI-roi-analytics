"""Load raw CSV/TSV files from data/ into PostgreSQL raw schema."""

import logging
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

DATA_DIR = Path(__file__).parent.parent / "data"
DB_URL = os.getenv("DATABASE_URL")
if not DB_URL:
    raise EnvironmentError("DATABASE_URL is not set. Copy .env.example to .env and fill in the values.")
CHUNK_SIZE = 200_000

# Maps raw table name -> file path (relative to DATA_DIR)
# Criteo filename may vary depending on Kaggle upload version; we auto-detect.
OLIST_FILES = {
    "olist_customers":       "olist/olist_customers_dataset.csv",
    "olist_orders":          "olist/olist_orders_dataset.csv",
    "olist_order_items":     "olist/olist_order_items_dataset.csv",
    "olist_order_payments":  "olist/olist_order_payments_dataset.csv",
    "olist_products":        "olist/olist_products_dataset.csv",
    "olist_sellers":         "olist/olist_sellers_dataset.csv",
    "olist_leads_qualified": "olist/olist_marketing_qualified_leads_dataset.csv",
    "olist_leads_closed":    "olist/olist_closed_deals_dataset.csv",
}


def detect_criteo_file() -> Path | None:
    """Return path to the Criteo TSV/CSV file (name varies by upload)."""
    criteo_dir = DATA_DIR / "criteo"
    for pattern in ["*.tsv.gz", "*.tsv", "*.csv.gz", "*.csv"]:
        matches = list(criteo_dir.glob(pattern))
        if matches:
            return matches[0]
    return None


def load_table(engine, table_name: str, file_path: Path, sep: str = ",") -> None:
    log.info("Loading %s from %s...", table_name, file_path.name)

    reader = pd.read_csv(
        file_path,
        sep=sep,
        chunksize=CHUNK_SIZE,
        low_memory=False,
    )

    total_rows = 0
    for i, chunk in enumerate(reader):
        chunk.columns = [c.strip().lower().replace(" ", "_") for c in chunk.columns]
        if_exists = "replace" if i == 0 else "append"
        chunk.to_sql(
            name=table_name,
            con=engine,
            schema="raw",
            if_exists=if_exists,
            index=False,
            method="multi",
        )
        total_rows += len(chunk)
        log.info("  chunk %d — %d rows so far", i + 1, total_rows)

    log.info("  done: %d total rows -> raw.%s", total_rows, table_name)


def main() -> None:
    engine = create_engine(DB_URL)

    with engine.connect() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
        conn.commit()

    # --- Criteo ---
    criteo_file = detect_criteo_file()
    if criteo_file is None:
        log.warning("Criteo file not found in data/criteo/. Run 'make download' first.")
    else:
        sep = "\t" if criteo_file.suffix in (".tsv", ".gz") and "tsv" in criteo_file.name else ","
        load_table(engine, "criteo_events", criteo_file, sep=sep)

    # --- Olist ---
    for table_name, rel_path in OLIST_FILES.items():
        file_path = DATA_DIR / rel_path
        if not file_path.exists():
            log.warning("File not found, skipping: %s", file_path)
            continue
        load_table(engine, table_name, file_path)

    log.info("Raw load complete.")


if __name__ == "__main__":
    main()
