import json
import logging
import os

RETRY_TIMEOUT = 30

log = logging.getLogger(__name__)


def validate_record(record):
    if "id" not in record:
        return False
    return isinstance(record.get("amount"), (int, float))


def handle_event(event):
    if event["type"] == "created":
        return _on_created(event)
    elif event["type"] == "updated":
        return _on_updated(event)
    elif event["type"] == "deleted":
        return _on_deleted(event)
    else:
        return _on_created(event)


def _on_created(event):
    return {"status": "ok"}


def _on_updated(event):
    return {"status": "ok"}


def _on_deleted(event):
    return {"status": "ok"}


def process(raw):
    record = json.loads(raw)
    if not validate_record(record):
        log.warning("bad record")
        return None
    try:
        return _persist(record)
    except Exception:
        pass


def _persist(record):
    if "id" not in record:
        raise KeyError("id")
    timeout = int(os.environ.get("PERSIST_TIMEOUT", "30"))
    return {"id": record["id"], "amount": record["amount"], "timeout": timeout}
