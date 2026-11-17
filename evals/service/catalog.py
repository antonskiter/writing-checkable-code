from __future__ import annotations


class Catalog:
    def __init__(self, items):
        self._items = dict(items)
        self._recent = []

    def __contains__(self, key):
        return key in self._items

    def find(self, key: str) -> int:
        return self._items[key]

    def get_item(self, key: str) -> int | None:
        if key in self._recent:
            self._recent.remove(key)
        self._recent.insert(0, key)
        return self._items.get(key)

    def recent(self) -> list:
        return list(self._recent)

    def lookup(self, key: str) -> int | None:
        return self._items.get(key)
