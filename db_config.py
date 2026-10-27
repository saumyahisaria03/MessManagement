"""Shared MySQL connection settings and SQL helpers. Override with environment variables."""
import os
import re

MYSQL_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "127.0.0.1"),
    "port": int(os.getenv("MYSQL_PORT", "3306")),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", ""),
}
DB_NAME = "mess_management"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def split_sql(text):
    """Split a SQL script into statements.

    Quote-aware: a ';' inside '...', "..." or `...` does not end a statement.
    '-- line' and '/* block */' comments are dropped. DELIMITER blocks
    (triggers / stored procedures) are not supported by design.
    """
    stmts, buf = [], []
    i, n = 0, len(text)
    quote = None
    while i < n:
        c = text[i]
        if quote:
            buf.append(c)
            if c == "\\" and quote != "`" and i + 1 < n:
                buf.append(text[i + 1])
                i += 1
            elif c == quote:
                quote = None
        elif c in ("'", '"', "`"):
            quote = c
            buf.append(c)
        elif text.startswith("--", i) and (i + 2 >= n or text[i + 2] in " \t\r\n"):
            while i < n and text[i] != "\n":
                i += 1
            continue
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            i = n if end == -1 else end + 2
            continue
        elif c == ";":
            s = "".join(buf).strip()
            if s:
                stmts.append(s)
            buf = []
        else:
            buf.append(c)
        i += 1
    s = "".join(buf).strip()
    if s:
        stmts.append(s)
    return stmts


QUERY_HEADER = re.compile(r"(?m)^--\s*QUERY\s+(\d+):\s*(.*)$")


def split_titled_queries(text):
    """Return (preamble_statements, [(number, title, [statements])]) from queries.sql."""
    marks = list(QUERY_HEADER.finditer(text))
    pre = split_sql(text[: marks[0].start()]) if marks else split_sql(text)
    out = []
    for k, m in enumerate(marks):
        end = marks[k + 1].start() if k + 1 < len(marks) else len(text)
        out.append((int(m.group(1)), m.group(2).strip(), split_sql(text[m.end():end])))
    return pre, out