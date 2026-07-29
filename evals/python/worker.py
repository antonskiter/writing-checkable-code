import time

import requests


def fetch_with_retry(url):
    deadline = time.time() + 30
    while time.time() < deadline:
        response = requests.get(url, timeout=5)
        if response.status_code < 500:
            return response.json()
        time.sleep(1)
    raise TimeoutError(url)


def stamp(payload):
    payload["fetched_at"] = time.time()
    return payload
