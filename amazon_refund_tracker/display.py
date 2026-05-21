"""Rich terminal display for refund tracking results."""

from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.text import Text
from rich import box
from .models import Return

console = Console()


def _status_color(status: str) -> str:
    s = status.lower()
    if "refund" in s and ("issued" in s or "ed" in s):
        return "green"
    if "pending" in s or "processing" in s or "awaiting" in s or "requested" in s:
        return "yellow"
    if "rejected" in s or "denied" in s:
        return "red"
    if "received" in s:
        return "cyan"
    return "white"


def print_summary(returns: list[Return]) -> None:
    if not returns:
        console.print(Panel("[yellow]No return/refund records found.[/yellow]", title="Amazon Refund Tracker"))
        return

    total_expected  = sum(r.refund_amount or 0 for r in returns)
    total_fees      = sum(r.fees_charged for r in returns)
    total_net       = total_expected - total_fees
    pending_count   = sum(1 for r in returns if "pending" in r.refund_status.lower()
                          or "processing" in r.refund_status.lower()
                          or "requested" in r.refund_status.lower())
    refunded_count  = sum(1 for r in returns if "refund" in r.refund_status.lower()
                          and "pending" not in r.refund_status.lower())

    summary = (
        f"[bold]Total returns tracked:[/bold] {len(returns)}   "
        f"[green]Refunded: {refunded_count}[/green]   "
        f"[yellow]Pending: {pending_count}[/yellow]\n"
        f"[bold]Expected refunds:[/bold] [green]${total_expected:.2f}[/green]   "
        f"[bold]Fees charged:[/bold] [red]${total_fees:.2f}[/red]   "
        f"[bold]Net refund:[/bold] [{'green' if total_net >= 0 else 'red'}]${total_net:.2f}[/]"
    )
    console.print(Panel(summary, title="[bold cyan]Amazon Refund Tracker — Summary[/bold cyan]", expand=False))


def print_returns_table(returns: list[Return]) -> None:
    if not returns:
        return

    table = Table(
        title="Return & Refund Details",
        box=box.ROUNDED,
        show_header=True,
        header_style="bold magenta",
        expand=True,
    )

    table.add_column("Order ID",       style="dim",    no_wrap=True, width=18)
    table.add_column("Item",           max_width=35)
    table.add_column("Initiated",      width=14)
    table.add_column("Status",         width=18)
    table.add_column("Expected $",     justify="right", width=11)
    table.add_column("Fees $",         justify="right", width=9)
    table.add_column("Net $",          justify="right", width=10)
    table.add_column("Days Pending",   justify="right", width=12)

    for r in returns:
        color    = _status_color(r.refund_status)
        fees_str = f"[red]-${r.fees_charged:.2f}[/red]" if r.fees_charged > 0 else "[dim]—[/dim]"
        net      = r.net_refund
        net_str  = f"[{'green' if (net or 0) >= 0 else 'red'}]${net:.2f}[/]" if net is not None else "[dim]?[/dim]"
        amt_str  = f"${r.refund_amount:.2f}" if r.refund_amount else "[dim]?[/dim]"
        days     = r.days_pending
        days_str = str(days) if days is not None else "—"
        if days and days > 14:
            days_str = f"[red]{days_str}[/red]"
        elif days and days > 7:
            days_str = f"[yellow]{days_str}[/yellow]"

        table.add_row(
            r.order_id,
            r.item_name[:35],
            r.return_initiated or "—",
            f"[{color}]{r.refund_status}[/{color}]",
            amt_str,
            fees_str,
            net_str,
            days_str,
        )

    console.print(table)


def print_fee_alerts(returns: list[Return]) -> None:
    flagged = [r for r in returns if r.fees_charged > 0]
    if not flagged:
        console.print("[green]No unexpected fees detected.[/green]")
        return

    console.print(f"\n[bold red]Fee Alerts — {len(flagged)} return(s) have fees deducted:[/bold red]")
    for r in flagged:
        console.print(
            f"  [yellow]Order {r.order_id}[/yellow]  {r.item_name[:40]}\n"
            f"    Fees: {', '.join(r.fee_breakdown) or f'${r.fees_charged:.2f}'}\n"
            f"    Expected ${r.refund_amount or 0:.2f} → Net ${r.net_refund or 0:.2f}"
        )


def print_long_pending(returns: list[Return], threshold_days: int = 10) -> None:
    overdue = [r for r in returns if (r.days_pending or 0) >= threshold_days
               and "pending" in r.refund_status.lower()]
    if not overdue:
        return
    console.print(f"\n[bold red]Overdue Refunds (>{threshold_days} days):[/bold red]")
    for r in overdue:
        console.print(
            f"  [red]Order {r.order_id}[/red]  {r.item_name[:40]}  "
            f"— {r.days_pending} days since return  "
            f"(expected ${r.refund_amount or 0:.2f})"
        )
