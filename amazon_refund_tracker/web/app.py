"""Flask web application for Amazon Refund Tracker."""

import io
import csv
import os
from pathlib import Path
from dotenv import load_dotenv
from flask import Flask, render_template, request, jsonify, Response, send_file, redirect, url_for

from ..storage import init_db, load_all_returns, export_csv
from .scanner import orchestrator

load_dotenv(Path.home() / ".amazon_refund_tracker" / ".env")
load_dotenv()

app = Flask(__name__, template_folder="templates", static_folder="static")
app.secret_key = os.urandom(24)


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

def _return_to_dict(r) -> dict:
    return {
        "return_id":           r.return_id,
        "order_id":            r.order_id,
        "item_name":           r.item_name,
        "order_date":          r.order_date,
        "return_initiated":    r.return_initiated,
        "refund_status":       r.refund_status,
        "refund_amount":       r.refund_amount,
        "fees_charged":        r.fees_charged,
        "net_refund":          r.net_refund,
        "fee_breakdown":       r.fee_breakdown,
        "carrier":             r.carrier,
        "tracking_number":     r.tracking_number,
        "expected_refund_date": r.expected_refund_date,
        "days_pending":        r.days_pending,
        "scraped_at":          r.scraped_at,
    }


def _summary(returns):
    total_exp  = sum(r.refund_amount or 0 for r in returns)
    total_fees = sum(r.fees_charged for r in returns)
    pending    = sum(1 for r in returns if _is_pending(r.refund_status))
    refunded   = sum(1 for r in returns if _is_refunded(r.refund_status))
    return {
        "total":        len(returns),
        "pending":      pending,
        "refunded":     refunded,
        "total_expected": round(total_exp, 2),
        "total_fees":   round(total_fees, 2),
        "net":          round(total_exp - total_fees, 2),
    }


def _is_pending(status: str) -> bool:
    s = status.lower()
    return any(w in s for w in ("pending", "processing", "awaiting", "requested", "received"))


def _is_refunded(status: str) -> bool:
    s = status.lower()
    return "refund" in s and not _is_pending(status)


# ------------------------------------------------------------------
# Pages
# ------------------------------------------------------------------

@app.route("/")
def dashboard():
    init_db()
    returns = load_all_returns()
    summary = _summary(returns)
    fee_alerts  = [r for r in returns if r.fees_charged > 0]
    overdue     = [r for r in returns if (r.days_pending or 0) >= 10 and _is_pending(r.refund_status)]
    saved_email = os.environ.get("AMAZON_EMAIL", "")
    return render_template(
        "index.html",
        returns=[_return_to_dict(r) for r in returns],
        summary=summary,
        fee_alerts=[_return_to_dict(r) for r in fee_alerts],
        overdue=[_return_to_dict(r) for r in overdue],
        saved_email=saved_email,
        scanning=orchestrator.running,
    )


# ------------------------------------------------------------------
# Scan API
# ------------------------------------------------------------------

@app.route("/api/scan/start", methods=["POST"])
def scan_start():
    if orchestrator.running:
        return jsonify({"ok": False, "error": "Scan already running"}), 409
    data     = request.get_json(silent=True) or {}
    email    = data.get("email", os.environ.get("AMAZON_EMAIL", "")).strip()
    password = data.get("password", os.environ.get("AMAZON_PASSWORD", "")).strip()
    headless = data.get("headless", True)
    if not email or not password:
        return jsonify({"ok": False, "error": "Email and password are required"}), 400
    orchestrator.start(email, password, headless=headless)
    return jsonify({"ok": True})


@app.route("/api/scan/events")
def scan_events():
    return Response(
        orchestrator.sse_stream(),
        mimetype="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@app.route("/api/scan/otp", methods=["POST"])
def scan_otp():
    data = request.get_json(silent=True) or {}
    otp  = str(data.get("otp", "")).strip()
    if not otp:
        return jsonify({"ok": False, "error": "OTP is required"}), 400
    orchestrator.provide_otp(otp)
    return jsonify({"ok": True})


# ------------------------------------------------------------------
# Data API
# ------------------------------------------------------------------

@app.route("/api/returns")
def api_returns():
    returns = load_all_returns()
    return jsonify([_return_to_dict(r) for r in returns])


@app.route("/api/export/csv")
def export_csv_route():
    returns = load_all_returns()
    buf = io.StringIO()
    fieldnames = [
        "return_id", "order_id", "item_name", "order_date",
        "return_initiated", "refund_status", "refund_amount",
        "fees_charged", "net_refund", "fee_breakdown",
        "carrier", "tracking_number", "expected_refund_date",
        "days_pending", "scraped_at",
    ]
    writer = csv.DictWriter(buf, fieldnames=fieldnames)
    writer.writeheader()
    for r in returns:
        d = _return_to_dict(r)
        d["fee_breakdown"] = "; ".join(d["fee_breakdown"] or [])
        writer.writerow({k: d.get(k) for k in fieldnames})

    buf.seek(0)
    return Response(
        buf.getvalue(),
        mimetype="text/csv",
        headers={"Content-Disposition": "attachment; filename=amazon_refunds.csv"},
    )


def run(host: str = "127.0.0.1", port: int = 5050, debug: bool = False) -> None:
    init_db()
    app.run(host=host, port=port, debug=debug, threaded=True)
