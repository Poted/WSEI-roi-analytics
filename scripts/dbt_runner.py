"""Run dbt commands with .env loaded into the environment."""

import os
import subprocess
import sys
from pathlib import Path

from dotenv import load_dotenv

ROOT = Path(__file__).parent.parent
load_dotenv(ROOT / ".env")

dbt_dir = ROOT / "dbt"
result = subprocess.run(["dbt"] + sys.argv[1:], cwd=dbt_dir, env=os.environ)
sys.exit(result.returncode)
