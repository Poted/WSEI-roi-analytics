"""Download Criteo and Olist datasets from Kaggle."""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

DATA_DIR = Path(__file__).parent.parent / "data"

DATASETS = [
    {
        "slug": "sharatsachin/criteo-attribution-modeling",
        "dest": DATA_DIR / "criteo",
        "name": "Criteo Attribution Modeling",
    },
    {
        "slug": "olistbr/brazilian-ecommerce",
        "dest": DATA_DIR / "olist",
        "name": "Olist Brazilian E-Commerce",
    },
    {
        "slug": "olistbr/marketing-funnel-olist",
        "dest": DATA_DIR / "olist",
        "name": "Olist Marketing Funnel",
    },
]


def download(dataset: dict) -> None:
    import kaggle  # imported here so missing creds give a clear error

    dest = dataset["dest"]
    dest.mkdir(parents=True, exist_ok=True)

    print(f"Downloading {dataset['name']}...")
    kaggle.api.dataset_download_files(
        dataset["slug"],
        path=str(dest),
        unzip=True,
        quiet=False,
    )
    print(f"  -> saved to {dest}")


def main() -> None:
    kaggle_username = os.getenv("KAGGLE_USERNAME")
    kaggle_key = os.getenv("KAGGLE_KEY")

    if kaggle_username and kaggle_key:
        os.environ["KAGGLE_USERNAME"] = kaggle_username
        os.environ["KAGGLE_KEY"] = kaggle_key
    elif not Path("~/.kaggle/kaggle.json").expanduser().exists():
        print(
            "ERROR: Kaggle credentials not found.\n"
            "  Option 1: set KAGGLE_USERNAME and KAGGLE_KEY in .env\n"
            "  Option 2: place kaggle.json in ~/.kaggle/kaggle.json\n"
            "  Get your key at: https://www.kaggle.com/settings -> API"
        )
        sys.exit(1)

    for dataset in DATASETS:
        try:
            download(dataset)
        except Exception as exc:
            print(f"ERROR downloading {dataset['name']}: {exc}")
            sys.exit(1)

    print("\nAll datasets downloaded successfully.")


if __name__ == "__main__":
    main()
