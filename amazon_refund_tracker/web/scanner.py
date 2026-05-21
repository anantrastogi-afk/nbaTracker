"""
Background scan orchestrator with SSE event queue and OTP callback support.
One global instance is shared across Flask requests.
"""

import threading
import queue
import json
import time
from typing import Optional


class ScanOrchestrator:
    def __init__(self):
        self._lock = threading.Lock()
        self._running = False
        self._event_queue: queue.Queue = queue.Queue()
        self._otp_event = threading.Event()
        self._otp_value: Optional[str] = None

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    @property
    def running(self) -> bool:
        return self._running

    def start(self, email: str, password: str, headless: bool = True) -> bool:
        with self._lock:
            if self._running:
                return False
            self._running = True
            self._otp_event.clear()
            self._otp_value = None
            # Drain stale events
            while not self._event_queue.empty():
                try:
                    self._event_queue.get_nowait()
                except queue.Empty:
                    break

        t = threading.Thread(
            target=self._run_scan,
            args=(email, password, headless),
            daemon=True,
        )
        t.start()
        return True

    def provide_otp(self, otp: str) -> None:
        self._otp_value = otp
        self._otp_event.set()

    def sse_stream(self):
        """Generator for Flask SSE response. Yields formatted SSE lines."""
        while True:
            try:
                event = self._event_queue.get(timeout=25)
            except queue.Empty:
                yield _sse("heartbeat", {})
                continue

            yield _sse(event["type"], event)

            if event["type"] in ("done", "error"):
                break

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _emit(self, type_: str, **kwargs) -> None:
        self._event_queue.put({"type": type_, **kwargs})

    def _otp_callback(self, prompt: str) -> Optional[str]:
        self._emit("otp_required", prompt=prompt)
        self._otp_event.wait(timeout=300)
        self._otp_event.clear()
        return self._otp_value

    def _status_callback(self, msg: str) -> None:
        self._emit("status", message=msg)

    def _run_scan(self, email: str, password: str, headless: bool) -> None:
        try:
            from ..browser import AmazonSession
            from ..storage import init_db, upsert_return

            self._emit("status", message="Launching browser…")
            init_db()

            with AmazonSession(
                email, password,
                headless=headless,
                otp_callback=self._otp_callback,
                status_callback=self._status_callback,
            ) as session:
                self._emit("status", message="Connecting to Amazon…")
                if not session.ensure_logged_in():
                    self._emit("error", message="Login failed. Check credentials or complete OTP.")
                    return

                self._emit("status", message="Logged in. Scraping Returns Centre…")
                returns = session.scrape_returns()

                if not returns:
                    self._emit("status", message="Nothing in Returns Centre — scanning order history…")
                    returns = session.scrape_order_history_for_refunds(max_pages=4)

                for r in returns:
                    upsert_return(r)

            self._emit("done", count=len(returns),
                       message=f"Scan complete — {len(returns)} record(s) saved.")
        except Exception as exc:
            self._emit("error", message=str(exc))
        finally:
            with self._lock:
                self._running = False


def _sse(event: str, data: dict) -> str:
    payload = json.dumps({k: v for k, v in data.items() if k != "type"})
    return f"event: {event}\ndata: {payload}\n\n"


# Singleton used by the Flask app
orchestrator = ScanOrchestrator()
