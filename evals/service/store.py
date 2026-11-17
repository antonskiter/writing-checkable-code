import contextlib
import threading
import time
from concurrent.futures import ThreadPoolExecutor


class SerializationFailure(Exception):
    pass


class Store:
    """A connection whose driver runs one statement at a time."""

    def __init__(self, balances, refusals):
        self.balances = dict(balances)
        self._refusals = refusals
        self._lock = threading.Lock()
        self.in_flight = 0
        self.peak = 0

    @contextlib.contextmanager
    def transaction(self):
        pending = dict(self.balances)
        yield pending
        if self._refusals:
            self._refusals -= 1
            raise SerializationFailure("commit refused: conflict")
        self.balances = pending

    def query(self, key):
        with self._lock:
            self.in_flight += 1
            self.peak = max(self.peak, self.in_flight)
        time.sleep(0.05)
        with self._lock:
            self.in_flight -= 1
        return self.balances[key]


def transfer(store, source, target, amount):
    try:
        with store.transaction() as pending:
            pending[source] -= amount
            pending[target] += amount
    except SerializationFailure:
        return "conflict"
    return "done"


def load_all(store, keys):
    with ThreadPoolExecutor() as pool:
        return list(pool.map(store.query, keys))
