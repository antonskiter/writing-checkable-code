"""Column rendering for the invoice report."""


def render_cell(label, value, unit, precision, align, width, fill):
    """Render one cell.

    label   text printed before the value
    value   the number to format
    unit    text printed after the value, may be empty
    precision  digits after the decimal point
    align   "left" or "right"
    width   total column width in characters
    fill    single character used to pad to width
    """
    body = f"{label}{value:.{precision}f}{unit}"
    if align == "right":
        return body.rjust(width, fill)
    return body.ljust(width, fill)


def on_invoice_sent(event):
    return {"status": "queued"}


def on_invoice_paid(event):
    return {"status": "queued"}


def on_invoice_void(event):
    return {"status": "queued"}
