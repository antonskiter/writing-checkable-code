import threading


class Connection:
    def __init__(self):
        self.open = True
        self.writes = []

    def write(self, value):
        if not self.open:
            raise RuntimeError(f"write {value!r} on a closed connection")
        self.writes.append(value)


class Session:
    def __init__(self, connect):
        self._connect = connect
        self._conn = connect()

    def submit(self, value, delay):
        threading.Timer(delay, self._conn.write, (value,)).start()

    def notify(self, value):
        if self._conn is None:
            self._conn = self._connect()
        self._conn.write(value)

    def close(self):
        self._conn.open = False
        self._conn = None
