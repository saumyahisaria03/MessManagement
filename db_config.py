"""Shared MySQL connection settings. Override with environment variables."""
import os

MYSQL_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "127.0.0.1"),
    "port": int(os.getenv("MYSQL_PORT", "3306")),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", ""),
}
DB_NAME = "mess_management"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def split_sql(text):
    """Split a SQL script into statements (drops full-line '--' comments)."""
    lines = [l for l in text.splitlines() if not l.strip().startswith("--")]
    return [s.strip() for s in "\n".join(lines).split(";") if s.strip()]