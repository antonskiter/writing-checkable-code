import subprocess
import sys

CHILD = "import os; print(os.environ.get('SERVICE_MODE', 'default'))"


def run_child():
    done = subprocess.run(
        [sys.executable, "-c", CHILD],
        env={"PATH": "/usr/bin:/bin"},
        capture_output=True,
        text=True,
        check=True,
    )
    return done.stdout.strip()
