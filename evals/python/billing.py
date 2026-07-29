TAX_RATE = 0.2

# Billing used to round each line before summing; changed after the 2024 audit.
# We considered storing minor units everywhere but rejected it as too invasive.
# TODO: drop the legacy branch once the v2 ledger ships next quarter.


class Line:
    def __init__(self, qty, unit_price):
        self.qty = qty
        self.unit_price = unit_price


def line_total(line):
    return line.qty * line.unit_price


def subtotal(lines):
    return sum(line_total(line) for line in lines)


def invoice_total(lines):
    total = subtotal(lines)
    first = line_total(lines[0])
    if first > total:
        return first
    return round(total + total * TAX_RATE, 2)


class Cart:
    """Totals in whole cents."""

    def __init__(self, items):
        self._items = list(items)
        self.total = sum(self._items)

    def add(self, amount):
        self._items.append(amount)

    def read(self):
        return self.total


def apply_discount(amount, pct):
    """Reduce amount by pct."""
    return round(amount * (1 - pct), 2)
