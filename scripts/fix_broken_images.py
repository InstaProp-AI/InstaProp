#!/usr/bin/env python3
import argparse
import csv
import os
import re
import sqlite3
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional, Sequence, Tuple
from functools import lru_cache

import urllib.request
import urllib.error


IMAGE_COLUMN_SUBSTRINGS = (
    "photo",
    "cover",
    "image",
    "picture",
    "logo",
    "avatar",
    "banner",
    "thumb",
    "thumbnail",
    "pic",
    "icon",
    "url",  # often used like ImageUrl, CoverUrl, etc.
)
TEXT_TYPES = {"TEXT", "VARCHAR", "NVARCHAR", "CHAR", "CLOB"}
CORE_IMAGE_TOKENS = {
    "photo",
    "cover",
    "image",
    "picture",
    "logo",
    "avatar",
    "banner",
    "thumb",
    "thumbnail",
    "pic",
    "icon",
}
EXCLUDE_TOKENS = {"delete", "remove", "del"}


@dataclass
class ColumnInfo:
    name: str
    type: str
    is_primary_key: bool


@dataclass
class PlannedChange:
    table: str
    key_column: str
    key_value: object
    column: str
    old_url: str
    new_url: str


def log(msg: str) -> None:
    print(msg, flush=True)


def ensure_dir(path: str) -> None:
    if path and not os.path.isdir(path):
        os.makedirs(path, exist_ok=True)


def discover_tables(conn: sqlite3.Connection, allowlist: Optional[Sequence[str]] = None) -> List[str]:
    cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [r[0] for r in cur.fetchall()]
    if allowlist:
        allow = {t.lower() for t in allowlist}
        tables = [t for t in tables if t.lower() in allow]
    return tables


def get_columns(conn: sqlite3.Connection, table: str) -> List[ColumnInfo]:
    cols: List[ColumnInfo] = []
    for cid, name, col_type, notnull, dflt, pk in conn.execute(f"PRAGMA table_info({table})"):
        col_upper = (col_type or "").upper()
        cols.append(ColumnInfo(name=name, type=col_upper, is_primary_key=bool(pk)))
    return cols


def pick_key_column(columns: List[ColumnInfo]) -> Optional[str]:
    for c in columns:
        if c.is_primary_key:
            return c.name
    return None


def is_likely_image_column(col: ColumnInfo) -> bool:
    if col.type not in TEXT_TYPES:
        return False
    lname = col.name.lower()
    if any(ex in lname for ex in EXCLUDE_TOKENS):
        return False
    has_core = any(tok in lname for tok in CORE_IMAGE_TOKENS)
    if not has_core:
        return False
    return True


def is_plausible_url(value: str, https_only: bool) -> bool:
    if not value or not isinstance(value, str):
        return False
    value = value.strip()
    if https_only and not value.lower().startswith("https://"):
        return False
    if not (value.lower().startswith("http://") or value.lower().startswith("https://")):
        return False
    return True


def http_head(url: str, timeout: int) -> Tuple[int, Dict[str, str]]:
    req = urllib.request.Request(url, method="HEAD")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        status = resp.getcode()
        headers = {k.lower(): v for k, v in resp.headers.items()}
        return status, headers


def http_get_bytes(url: str, timeout: int, max_bytes: int = 2048) -> Tuple[int, Dict[str, str], bytes]:
    req = urllib.request.Request(url, method="GET")
    req.add_header("Range", f"bytes=0-{max_bytes - 1}")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        status = resp.getcode()
        headers = {k.lower(): v for k, v in resp.headers.items()}
        data = resp.read(max_bytes)
        return status, headers, data


def validate_image_url(url: str, timeout: int, retries: int, quick: bool) -> bool:
    last_exc: Optional[Exception] = None
    for attempt in range(retries + 1):
        try:
            if quick:
                status, headers, data = http_get_bytes(url, timeout)
                if status == 200 and headers.get("content-type", "").lower().startswith("image/") and len(data) >= 1024:
                    return True
            else:
                # Prefer HEAD
                try:
                    status, headers = http_head(url, timeout)
                    if status == 200 and headers.get("content-type", "").lower().startswith("image/"):
                        clen = headers.get("content-length")
                        if clen is not None:
                            try:
                                if int(clen) >= 1024:
                                    return True
                            except ValueError:
                                pass
                        status_g, headers_g, data = http_get_bytes(url, timeout)
                        return status_g == 200 and headers_g.get("content-type", "").lower().startswith("image/") and len(data) >= 1024
                except urllib.error.HTTPError as e:
                    if e.code not in (403, 405):
                        last_exc = e
                # GET fallback or if HEAD insufficient
                status, headers, data = http_get_bytes(url, timeout)
                if status == 200 and headers.get("content-type", "").lower().startswith("image/") and len(data) >= 1024:
                    return True
        except Exception as e:  # noqa: BLE001
            last_exc = e
            time.sleep(min(1.0 * (attempt + 1), 3.0))
    return False


@lru_cache(maxsize=200000)
def validate_image_url_cached(url: str, timeout: int, retries: int, quick: bool) -> bool:
    return validate_image_url(url=url, timeout=timeout, retries=retries, quick=quick)


def placeholder_for(table: str, key_value: object, column: str) -> str:
    base = table.lower()
    if base in ("property", "properties", "parent_property", "parentproperties", "childproperties", "propertyimages"):
        return f"https://picsum.photos/seed/property-{key_value}/1600/900"
    if base in ("developer", "developerprofiles", "developers"):
        return f"https://picsum.photos/seed/developer-{key_value}/800/800"
    if base in ("project", "projects"):
        return f"https://picsum.photos/seed/project-{key_value}/1400/900"
    if base in ("article", "news", "newsarticles"):
        # Wider if it's a cover-like column name
        if "cover" in column.lower():
            return f"https://picsum.photos/seed/article-{key_value}/1400/900"
        return f"https://picsum.photos/seed/article-{key_value}/1200/800"
    # Generic fallback
    return f"https://picsum.photos/seed/{base}-{key_value}/1200/800"


def collect_rows(conn: sqlite3.Connection, table: str, key_col: str, img_cols: List[str], https_only: bool) -> List[Tuple[object, Dict[str, Optional[str]]]]:
    cols = [key_col] + img_cols
    col_list = ", ".join([f'"{c}"' for c in cols])
    rows: List[Tuple[object, Dict[str, Optional[str]]]] = []
    for r in conn.execute(f"SELECT {col_list} FROM \"{table}\""):
        key_val = r[0]
        values = {img_cols[i]: r[i + 1] for i in range(len(img_cols))}
        # Filter to plausible URLs (skip nulls/bad strings)
        filtered = {c: v for c, v in values.items() if v and is_plausible_url(str(v), https_only)}
        if filtered:
            rows.append((key_val, filtered))
    return rows


def plan_changes_for_table(
    table: str,
    conn: sqlite3.Connection,
    key_col: str,
    img_cols: List[str],
    timeout: int,
    retries: int,
    concurrency: int,
    https_only: bool,
    quick: bool,
) -> List[PlannedChange]:
    tasks: List[Tuple[str, object, str, str]] = []
    data = collect_rows(conn, table, key_col, img_cols, https_only=https_only)
    for key_val, mapping in data:
        for col, url in mapping.items():
            tasks.append((table, key_val, col, url))

    planned: List[PlannedChange] = []

    def worker(t: Tuple[str, object, str, str]) -> Optional[PlannedChange]:
        t_table, key_val, col, url = t
        ok = validate_image_url_cached(url, timeout=timeout, retries=retries, quick=quick)
        if ok:
            return None
        new_url = placeholder_for(t_table, key_val, col)
        return PlannedChange(table=t_table, key_column=key_col, key_value=key_val, column=col, old_url=url, new_url=new_url)

    with ThreadPoolExecutor(max_workers=max(1, concurrency)) as pool:
        futures = [pool.submit(worker, t) for t in tasks]
        for f in as_completed(futures):
            pc = f.result()
            if pc is not None:
                planned.append(pc)
    return planned


def apply_changes(conn: sqlite3.Connection, changes: List[PlannedChange], log_dir: str) -> Tuple[str, str]:
    ensure_dir(log_dir)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    csv_path = os.path.join(log_dir, f"image_fixes_{ts}.csv")
    rollback_path = os.path.join(log_dir, f"image_fixes_{ts}_rollback.sql")

    with open(csv_path, "w", newline="", encoding="utf-8") as csvfile, open(rollback_path, "w", encoding="utf-8") as rb:
        writer = csv.writer(csvfile)
        writer.writerow(["table", "key_column", "key_value", "column", "old_url", "new_url", "status"])  # status will be "updated"

        conn.execute("BEGIN")
        try:
            for ch in changes:
                # CSV row
                writer.writerow([ch.table, ch.key_column, ch.key_value, ch.column, ch.old_url, ch.new_url, "updated"])

                # Rollback statement
                if isinstance(ch.key_value, str):
                    key_literal = ch.key_value.replace("'", "''")
                    rb.write(
                        f"UPDATE \"{ch.table}\" SET \"{ch.column}\"='{ch.old_url.replace("'", "''")}' WHERE \"{ch.key_column}\"='{key_literal}';\n"
                    )
                else:
                    rb.write(
                        f"UPDATE \"{ch.table}\" SET \"{ch.column}\"='{ch.old_url.replace("'", "''")}' WHERE \"{ch.key_column}\"={ch.key_value};\n"
                    )

                # Apply update
                if isinstance(ch.key_value, str):
                    conn.execute(
                        f"UPDATE \"{ch.table}\" SET \"{ch.column}\"=? WHERE \"{ch.key_column}\"=?",
                        (ch.new_url, ch.key_value),
                    )
                else:
                    conn.execute(
                        f"UPDATE \"{ch.table}\" SET \"{ch.column}\"=? WHERE \"{ch.key_column}\"=?",
                        (ch.new_url, ch.key_value),
                    )
            conn.execute("COMMIT")
        except Exception:
            conn.execute("ROLLBACK")
            raise

    return csv_path, rollback_path


def write_planned_csv(changes: List[PlannedChange], log_dir: str) -> str:
    ensure_dir(log_dir)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    csv_path = os.path.join(log_dir, f"image_fixes_{ts}_planned.csv")
    with open(csv_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["table", "key_column", "key_value", "column", "old_url", "new_url", "status"])  # status "planned"
        for ch in changes:
            writer.writerow([ch.table, ch.key_column, ch.key_value, ch.column, ch.old_url, ch.new_url, "planned"])
    return csv_path


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Fix broken image URLs in SQLite DB by replacing with placeholders.")
    parser.add_argument("--db", required=True, help="Path to SQLite database file")
    parser.add_argument("--tables", nargs="*", help="Optional list of tables to include")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true", help="Do not modify DB; only report planned changes")
    mode.add_argument("--apply", action="store_true", help="Apply changes to DB")
    parser.add_argument("--concurrency", type=int, default=8, help="Number of concurrent URL checks")
    parser.add_argument("--timeout", type=int, default=10, help="HTTP timeout in seconds per request")
    parser.add_argument("--retries", type=int, default=1, help="Retry count for HTTP checks")
    parser.add_argument("--log-dir", default="logs", help="Directory to write CSV and rollback files")
    parser.add_argument("--https-only", action="store_true", help="Only consider https:// URLs as candidates")
    parser.add_argument("--quick", action="store_true", help="Faster checks: skip HEAD, small ranged GET only")

    args = parser.parse_args(argv)

    if not os.path.isfile(args.db):
        log(f"ERROR: Database not found: {args.db}")
        return 2

    conn = sqlite3.connect(args.db)
    conn.row_factory = sqlite3.Row
    try:
        tables = discover_tables(conn, allowlist=args.tables)
        if not tables:
            log("No tables found to scan.")
            return 0

        total_changes: List[PlannedChange] = []
        for table in tables:
            cols = get_columns(conn, table)
            key_col = pick_key_column(cols) or "rowid"
            img_cols = [c.name for c in cols if is_likely_image_column(c)]
            if not img_cols:
                continue
            log(f"Scanning table '{table}' (key='{key_col}') columns={img_cols}")
            planned = plan_changes_for_table(
                table=table,
                conn=conn,
                key_col=key_col,
                img_cols=img_cols,
                timeout=args.timeout,
                retries=args.retries,
                concurrency=args.concurrency,
                https_only=args.https_only,
                quick=args.quick,
            )
            log(f"  Planned changes for '{table}': {len(planned)}")
            total_changes.extend(planned)

        log(f"Total planned changes: {len(total_changes)}")
        ensure_dir(args.log_dir)

        if args.dry_run:
            csv_path = write_planned_csv(total_changes, args.log_dir)
            log(f"Dry-run report written to: {csv_path}")
            return 0
        else:
            if not total_changes:
                log("No changes to apply.")
                return 0
            csv_path, rollback_path = apply_changes(conn, total_changes, args.log_dir)
            log(f"Applied updates. CSV: {csv_path}")
            log(f"Rollback SQL: {rollback_path}")
            return 0
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())


