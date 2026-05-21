from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class RefundItem:
    name: str
    quantity: int
    refund_amount: float


@dataclass
class Return:
    order_id: str
    return_id: str
    item_name: str
    order_date: Optional[str]
    return_initiated: Optional[str]
    refund_status: str           # Pending / Refunded / Processing / Rejected
    refund_amount: Optional[float]
    fees_charged: float          # restocking, return shipping, etc.
    fee_breakdown: list[str] = field(default_factory=list)
    carrier: Optional[str] = None
    tracking_number: Optional[str] = None
    expected_refund_date: Optional[str] = None
    raw_status_text: str = ""
    scraped_at: str = field(default_factory=lambda: datetime.now().isoformat())

    @property
    def net_refund(self) -> Optional[float]:
        if self.refund_amount is None:
            return None
        return self.refund_amount - self.fees_charged

    @property
    def days_pending(self) -> Optional[int]:
        if self.return_initiated is None:
            return None
        try:
            initiated = datetime.strptime(self.return_initiated, "%B %d, %Y")
            return (datetime.now() - initiated).days
        except ValueError:
            return None
