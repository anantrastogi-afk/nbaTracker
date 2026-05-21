import sqlite3
import json
from pathlib import Path
from typing import Optional
from datetime import datetime
from .models import Return

DB_PATH = Path.home() / ".amazon_refund_tracker" / "data.db"


def _connect() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    conn = _connect()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS returns (
            return_id       TEXT PRIMARY KEY,
            order_id        TEXT,
            item_name       TEXT,
            order_date      TEXT,
            return_initiated TEXT,
            refund_status   TEXT,
            refund_amount   REAL,
            fees_charged    REAL DEFAULT 0,
            fee_breakdown   TEXT DEFAULT '[]',
            carrier         TEXT,
            tracking_number TEXT,
            expected_refund_date TEXT,
            raw_status_text TEXT,
            scraped_at      TEXT
        )
    """)
    conn.commit()
    conn.close()


def upsert_return(r: Return) -> None:
    conn = _connect()
    conn.execute("""
        INSERT INTO returns (
            return_id, order_id, item_name, order_date, return_initiated,
            refund_status, refund_amount, fees_charged, fee_breakdown,
            carrier, tracking_number, expected_refund_date,
            raw_status_text, scraped_at
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        ON CONFLICT(return_id) DO UPDATE SET
            refund_status        = excluded.refund_status,
            refund_amount        = excluded.refund_amount,
            fees_charged         = excluded.fees_charged,
            fee_breakdown        = excluded.fee_breakdown,
            carrier              = excluded.carrier,
            tracking_number      = excluded.tracking_number,
            expected_refund_date = excluded.expected_refund_date,
            raw_status_text      = excluded.raw_status_text,
            scraped_at           = excluded.scraped_at
    """, (
        r.return_id, r.order_id, r.item_name, r.order_date,
        r.return_initiated, r.refund_status, r.refund_amount,
        r.fees_charged, json.dumps(r.fee_breakdown),
        r.carrier, r.tracking_number, r.expected_refund_date,
        r.raw_status_text, r.scraped_at,
    ))
    conn.commit()
    conn.close()


def load_all_returns() -> list[Return]:
    conn = _connect()
    rows = conn.execute("SELECT * FROM returns ORDER BY scraped_at DESC").fetchall()
    conn.close()
    result = []
    for row in rows:
        r = Return(
            return_id=row["return_id"],
            order_id=row["order_id"],
            item_name=row["item_name"],
            order_date=row["order_date"],
            return_initiated=row["return_initiated"],
            refund_status=row["refund_status"],
            refund_amount=row["refund_amount"],
            fees_charged=row["fees_charged"] or 0.0,
            fee_breakdown=json.loads(row["fee_breakdown"] or "[]"),
            carrier=row["carrier"],
            tracking_number=row["tracking_number"],
            expected_refund_date=row["expected_refund_date"],
            raw_status_text=row["raw_status_text"] or "",
        )
        r.scraped_at = row["scraped_at"]
        result.append(r)
    return result


def export_csv(path: str) -> None:
    import csv
    returns = load_all_returns()
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "return_id", "order_id", "item_name", "order_date",
            "return_initiated", "refund_status", "refund_amount",
            "fees_charged", "net_refund", "fee_breakdown",
            "carrier", "tracking_number", "expected_refund_date",
            "days_pending", "scraped_at",
        ])
        writer.writeheader()
        for r in returns:
            writer.writerow({
                "return_id": r.return_id,
                "order_id": r.order_id,
                "item_name": r.item_name,
                "order_date": r.order_date,
                "return_initiated": r.return_initiated,
                "refund_status": r.refund_status,
                "refund_amount": r.refund_amount,
                "fees_charged": r.fees_charged,
                "net_refund": r.net_refund,
                "fee_breakdown": "; ".join(r.fee_breakdown),
                "carrier": r.carrier,
                "tracking_number": r.tracking_number,
                "expected_refund_date": r.expected_refund_date,
                "days_pending": r.days_pending,
                "scraped_at": r.scraped_at,
            })
