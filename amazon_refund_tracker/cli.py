"""
Amazon Refund Tracker — CLI entry point.

Usage:
    python -m amazon_refund_tracker                  # Scan & show report
    python -m amazon_refund_tracker              # Scan & show report (CLI)
    python -m amazon_refund_tracker --web        # Launch web UI  ← NEW
    python -m amazon_refund_tracker --report     # Show saved data only (no scrape)
    python -m amazon_refund_tracker --export out.csv
    python -m amazon_refund_tracker --headless
    python -m amazon_refund_tracker --days 14
"""

import argparse
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

from .storage import init_db, upsert_return, load_all_returns, export_csv
from .display import console, print_summary, print_returns_table, print_fee_alerts, print_long_pending


def load_credentials() -> tuple[str, str]:
    load_dotenv(Path.home() / ".amazon_refund_tracker" / ".env")
    load_dotenv()  # also check cwd

    email    = os.environ.get("AMAZON_EMAIL", "").strip()
    password = os.environ.get("AMAZON_PASSWORD", "").strip()

    if not email:
        email = input("Amazon email: ").strip()
    if not password:
        import getpass
        password = getpass.getpass("Amazon password: ")

    return email, password


def run_scan(email: str, password: str, headless: bool) -> list:
    from .browser import AmazonSession
    with AmazonSession(email, password, headless=headless) as session:
        console.print("[cyan]Connecting to Amazon...[/cyan]")
        if not session.ensure_logged_in():
            console.print("[bold red]Login failed. Exiting.[/bold red]")
            sys.exit(1)
        console.print("[green]Logged in successfully.[/green]")

        console.print("[cyan]Scraping Returns Centre...[/cyan]")
        returns = session.scrape_returns()

        if not returns:
            console.print("[yellow]Returns Centre scan returned nothing — trying order history...[/yellow]")
            returns = session.scrape_order_history_for_refunds(max_pages=4)

    return returns


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Amazon Refund Tracker — monitor returns, refunds, and fees",
    )
    parser.add_argument("--web",      action="store_true", help="Launch web UI dashboard")
    parser.add_argument("--port",     type=int, default=5050, help="Web UI port (default 5050)")
    parser.add_argument("--host",     default="127.0.0.1",    help="Web UI host (default 127.0.0.1)")
    parser.add_argument("--report",   action="store_true", help="Show saved data without scraping")
    parser.add_argument("--export",   metavar="FILE",      help="Export results to CSV file")
    parser.add_argument("--headless", action="store_true", help="Run browser headlessly (no interactive OTP)")
    parser.add_argument("--days",     type=int, default=10, help="Days threshold for overdue alert (default 10)")
    args = parser.parse_args()

    if args.web:
        from .web.app import run as run_web
        console.print(f"[bold cyan]Starting web UI at http://{args.host}:{args.port}[/bold cyan]")
        console.print("[dim]Press Ctrl+C to stop.[/dim]")
        run_web(host=args.host, port=args.port, debug=False)
        return

    init_db()

    if args.export and args.report:
        # Just export stored data
        export_csv(args.export)
        console.print(f"[green]Exported to {args.export}[/green]")
        return

    if args.report:
        returns = load_all_returns()
        if not returns:
            console.print("[yellow]No data stored yet. Run without --report to scan Amazon first.[/yellow]")
            return
    else:
        email, password = load_credentials()
        returns = run_scan(email, password, headless=args.headless)

        if returns:
            console.print(f"[green]Found {len(returns)} return record(s). Saving...[/green]")
            for r in returns:
                upsert_return(r)
        else:
            console.print("[yellow]No return records found on this account.[/yellow]")
            returns = load_all_returns()  # fall back to stored data

    # Display
    console.rule("[bold cyan]Amazon Refund Tracker[/bold cyan]")
    print_summary(returns)
    print_returns_table(returns)
    print_fee_alerts(returns)
    print_long_pending(returns, threshold_days=args.days)

    if args.export:
        export_csv(args.export)
        console.print(f"\n[green]Exported to {args.export}[/green]")
