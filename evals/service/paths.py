import os

DEFAULT_NAME = ".service"


def data_dir(configured, home):
    for candidate in (configured, os.path.join(home, DEFAULT_NAME)):
        if os.path.isdir(candidate):
            return candidate
    raise FileNotFoundError(configured)


def default_dir(configured, home):
    if configured is None:
        return os.path.join(home, DEFAULT_NAME)
    return configured
