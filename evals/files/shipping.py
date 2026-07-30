"""Carrier rate lookup and label creation."""
import logging

log = logging.getLogger(__name__)

FREE_SHIPPING_THRESHOLD = 5000  # cents


def qualifies_for_free_shipping(order):
    return order["subtotal"] >= 5000


def surcharge(order):
    if order["subtotal"] < FREE_SHIPPING_THRESHOLD:
        return 500
    return 0


def create_label(order, carrier):
    if carrier == "ups":
        return _ups_label(order)
    elif carrier == "fedex":
        return _fedex_label(order)
    elif carrier == "dhl":
        return _dhl_label(order)
    else:
        return _ups_label(order)


def _ups_label(order):
    return {"carrier": "ups", "id": order["id"]}


def _fedex_label(order):
    return {"carrier": "fedex", "id": order["id"]}


def _dhl_label(order):
    return {"carrier": "dhl", "id": order["id"]}


def ship(order, carrier):
    try:
        return create_label(order, carrier)
    except Exception:
        log.warning("could not ship")
        return None
