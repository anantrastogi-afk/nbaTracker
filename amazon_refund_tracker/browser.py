"""
Browser automation for Amazon account access.
Uses Playwright in headed mode so the user can handle 2FA/OTP interactively.
Switches to headless after login is confirmed.
"""

import os
import re
import time
from typing import Optional
from pathlib import Path
from playwright.sync_api import sync_playwright, Page, Browser, BrowserContext, Playwright

from .models import Return

# Persist cookies/session between runs so re-login is rare
SESSION_DIR = Path.home() / ".amazon_refund_tracker" / "session"

AMAZON_BASE = "https://www.amazon.com"
RETURNS_URL = f"{AMAZON_BASE}/returns/homepage"
ORDERS_URL  = f"{AMAZON_BASE}/gp/css/order-history"


def _make_return_id(order_id: str, item_name: str, idx: int) -> str:
    slug = re.sub(r"[^a-zA-Z0-9]", "_", item_name[:30])
    return f"{order_id}__{slug}__{idx}"


def _parse_currency(text: str) -> Optional[float]:
    m = re.search(r"\$?([\d,]+\.?\d*)", text.replace(",", ""))
    return float(m.group(1)) if m else None


def _detect_fees(text: str) -> tuple[float, list[str]]:
    """Scan raw status text for known fee patterns and return total + breakdown."""
    total = 0.0
    breakdown: list[str] = []

    patterns = [
        (r"restocking fee[:\s]+\$?([\d,.]+)", "Restocking fee"),
        (r"return shipping[:\s]+\$?([\d,.]+)", "Return shipping"),
        (r"deducted[:\s]+\$?([\d,.]+)", "Deducted amount"),
        (r"charged[:\s]+\$?([\d,.]+)", "Charged amount"),
        (r"fee[:\s]+\$?([\d,.]+)", "Fee"),
    ]
    for pattern, label in patterns:
        for m in re.finditer(pattern, text, re.IGNORECASE):
            amt = float(m.group(1).replace(",", ""))
            total += amt
            breakdown.append(f"{label}: ${amt:.2f}")

    return total, breakdown


class AmazonSession:
    def __init__(self, email: str, password: str, headless: bool = False,
                 otp_callback=None, status_callback=None):
        self.email = email
        self.password = password
        self.headless = headless
        # otp_callback(prompt: str) -> str | None  — called when OTP/CAPTCHA needed
        self.otp_callback = otp_callback
        # status_callback(msg: str) — called with progress updates
        self.status_callback = status_callback
        self._pw: Optional[Playwright] = None
        self._browser: Optional[Browser] = None
        self._context: Optional[BrowserContext] = None
        self.page: Optional[Page] = None

    def __enter__(self):
        self._pw = sync_playwright().start()
        SESSION_DIR.mkdir(parents=True, exist_ok=True)

        # Use a persistent context so cookies survive across runs
        self._context = self._pw.chromium.launch_persistent_context(
            user_data_dir=str(SESSION_DIR),
            headless=self.headless,
            args=["--no-sandbox"],
            viewport={"width": 1280, "height": 900},
        )
        self.page = self._context.pages[0] if self._context.pages else self._context.new_page()
        return self

    def __exit__(self, *_):
        if self._context:
            self._context.close()
        if self._pw:
            self._pw.stop()

    # ------------------------------------------------------------------
    # Login
    # ------------------------------------------------------------------

    def ensure_logged_in(self) -> bool:
        """Navigate to Amazon and log in if needed. Returns True on success."""
        self.page.goto(AMAZON_BASE, timeout=30_000)
        time.sleep(1)

        # Already logged in?
        if self._is_logged_in():
            return True

        return self._do_login()

    def _is_logged_in(self) -> bool:
        greeting = self.page.query_selector("#nav-link-accountList-nav-line-1")
        if greeting:
            text = greeting.inner_text().strip().lower()
            return "sign in" not in text and "hello" in text
        return False

    def _do_login(self) -> bool:
        self.page.goto(f"{AMAZON_BASE}/ap/signin", timeout=30_000)
        time.sleep(1)

        # Email step
        email_field = self.page.query_selector("#ap_email")
        if email_field:
            email_field.fill(self.email)
            self.page.click("#continue")
            time.sleep(1)

        # Password step
        pw_field = self.page.query_selector("#ap_password")
        if pw_field:
            pw_field.fill(self.password)
            self.page.click("#signInSubmit")
            time.sleep(2)

        # OTP / CAPTCHA handling
        if not self._is_logged_in():
            otp_field = self.page.query_selector("#auth-mfa-otpcode, input[name='otpCode'], #otp")
            if otp_field and self.otp_callback:
                otp = self.otp_callback("Amazon sent a one-time password to your device. Enter it here:")
                if otp:
                    otp_field.fill(str(otp).strip())
                    submit = self.page.query_selector("#auth-signin-button, input[type='submit']")
                    if submit:
                        submit.click()
                    time.sleep(2)
            elif not self.headless:
                print(
                    "\n[!] Amazon is asking for OTP / CAPTCHA. "
                    "Please complete it in the browser window.\n"
                    "    Press ENTER here once you are signed in..."
                )
                input()
            else:
                return False

        return self._is_logged_in()

    # ------------------------------------------------------------------
    # Scrape returns
    # ------------------------------------------------------------------

    def _status(self, msg: str) -> None:
        if self.status_callback:
            self.status_callback(msg)

    def scrape_returns(self) -> list[Return]:
        """Navigate to the Returns centre and scrape all visible returns."""
        self._status("Loading Returns Centre…")
        self.page.goto(RETURNS_URL, timeout=30_000)
        time.sleep(2)

        returns: list[Return] = []

        # Amazon's returns page varies by account; try multiple selectors
        return_cards = self.page.query_selector_all("[data-component='returnItem'], .a-box-group, .return-card")

        if not return_cards:
            # Fallback: parse the whole page text and extract what we can
            returns = self._parse_returns_from_page()
        else:
            for idx, card in enumerate(return_cards):
                r = self._parse_card(card, idx)
                if r:
                    returns.append(r)

        return returns

    def _parse_returns_from_page(self) -> list[Return]:
        """Best-effort full-page text parse when structured selectors fail."""
        returns: list[Return] = []

        # Look for order-number anchors
        order_links = self.page.query_selector_all("a[href*='orderID'], a[href*='order-details']")
        seen_orders: set[str] = set()

        for link in order_links:
            href = link.get_attribute("href") or ""
            m = re.search(r"orderID=([A-Z0-9-]+)", href)
            if not m:
                m = re.search(r"order-details/([A-Z0-9-]+)", href)
            if not m:
                continue
            order_id = m.group(1)
            if order_id in seen_orders:
                continue
            seen_orders.add(order_id)

            # Navigate to individual order to get refund detail
            order_returns = self._scrape_order_for_refunds(order_id)
            returns.extend(order_returns)

        return returns

    def _scrape_order_for_refunds(self, order_id: str) -> list[Return]:
        """Visit the order detail page and pull refund info."""
        url = f"{AMAZON_BASE}/gp/css/summary/edit.html?orderID={order_id}"
        self.page.goto(url, timeout=30_000)
        time.sleep(1)
        page_text = self.page.inner_text("body")
        return self._extract_refunds_from_text(order_id, page_text)

    def _extract_refunds_from_text(self, order_id: str, text: str) -> list[Return]:
        returns: list[Return] = []
        lines = text.splitlines()

        # Find item names (lines near "Refund" keywords)
        refund_indices = [i for i, l in enumerate(lines) if re.search(r"refund|return", l, re.I)]
        if not refund_indices:
            return returns

        for i, idx in enumerate(refund_indices):
            # Take a window of surrounding lines as context
            window_start = max(0, idx - 5)
            window_end   = min(len(lines), idx + 10)
            window = "\n".join(lines[window_start:window_end])

            # Item name heuristic: longest non-empty line in window above the keyword
            candidate_lines = [l.strip() for l in lines[window_start:idx] if len(l.strip()) > 10]
            item_name = candidate_lines[-1] if candidate_lines else f"Item from {order_id}"

            refund_amount = _parse_currency(window)
            fees, fee_breakdown = _detect_fees(window)

            status_match = re.search(
                r"(Refund Issued|Refund Pending|Processing|Refunded|Rejected|"
                r"Return Received|Return Requested|Awaiting|Shipped)",
                window, re.I,
            )
            status = status_match.group(0).title() if status_match else "Unknown"

            date_match = re.search(r"(January|February|March|April|May|June|July|August|"
                                   r"September|October|November|December)\s+\d{1,2},\s+\d{4}", window)
            date_str = date_match.group(0) if date_match else None

            ret_id = _make_return_id(order_id, item_name, i)
            r = Return(
                order_id=order_id,
                return_id=ret_id,
                item_name=item_name,
                order_date=None,
                return_initiated=date_str,
                refund_status=status,
                refund_amount=refund_amount,
                fees_charged=fees,
                fee_breakdown=fee_breakdown,
                raw_status_text=window[:500],
            )
            returns.append(r)

        return returns

    def _parse_card(self, card, idx: int) -> Optional[Return]:
        """Parse a structured return card element."""
        text = card.inner_text()

        order_m = re.search(r"Order[:\s#]+([A-Z0-9-]{14,})", text, re.I)
        order_id = order_m.group(1) if order_m else f"UNKNOWN_{idx}"

        # Item name: first long line
        lines = [l.strip() for l in text.splitlines() if len(l.strip()) > 5]
        item_name = lines[0] if lines else "Unknown Item"

        status_m = re.search(
            r"(Refund Issued|Refund Pending|Processing|Refunded|Rejected|"
            r"Return Received|Return Requested|Awaiting|Shipped)",
            text, re.I,
        )
        status = status_m.group(0).title() if status_m else "Unknown"

        refund_amount = _parse_currency(text)
        fees, fee_breakdown = _detect_fees(text)

        date_m = re.search(r"(January|February|March|April|May|June|July|August|"
                           r"September|October|November|December)\s+\d{1,2},\s+\d{4}", text)
        date_str = date_m.group(0) if date_m else None

        tracking_m = re.search(r"tracking[:\s]+([A-Z0-9]{10,})", text, re.I)
        tracking = tracking_m.group(1) if tracking_m else None

        carrier_m = re.search(r"\b(UPS|USPS|FedEx|OnTrac|DHL|LaserShip)\b", text, re.I)
        carrier = carrier_m.group(0).upper() if carrier_m else None

        return Return(
            order_id=order_id,
            return_id=_make_return_id(order_id, item_name, idx),
            item_name=item_name,
            order_date=None,
            return_initiated=date_str,
            refund_status=status,
            refund_amount=refund_amount,
            fees_charged=fees,
            fee_breakdown=fee_breakdown,
            carrier=carrier,
            tracking_number=tracking,
            raw_status_text=text[:500],
        )

    # ------------------------------------------------------------------
    # Scrape order history for returns
    # ------------------------------------------------------------------

    def scrape_order_history_for_refunds(self, max_pages: int = 5) -> list[Return]:
        """Walk order history pages and flag orders with refund/return activity."""
        self._status("Scanning order history for refunds…")
        returns: list[Return] = []
        for page_num in range(max_pages):
            url = (
                f"{ORDERS_URL}?opt=ab&digitalOrders=1&unifiedOrders=1"
                f"&returnTo=&orderFilter=year-{2024 - page_num // 2}"  # iterate recent years
                f"&startIndex={page_num * 10}"
            )
            self.page.goto(url, timeout=30_000)
            time.sleep(1)

            order_ids = self._extract_order_ids_from_page()
            if not order_ids:
                break

            for oid in order_ids:
                page_text = self.page.inner_text("body")
                if re.search(r"refund|return", page_text, re.I):
                    r_list = self._scrape_order_for_refunds(oid)
                    returns.extend(r_list)

        return returns

    def _extract_order_ids_from_page(self) -> list[str]:
        hrefs = self.page.eval_on_selector_all(
            "a[href*='orderID'], a[href*='order-details']",
            "els => els.map(e => e.href)"
        )
        ids: list[str] = []
        for href in hrefs:
            m = re.search(r"orderID=([A-Z0-9-]+)", href)
            if not m:
                m = re.search(r"order-details/([A-Z0-9-]+)", href)
            if m and m.group(1) not in ids:
                ids.append(m.group(1))
        return ids
