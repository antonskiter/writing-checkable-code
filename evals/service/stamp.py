import time


def day_label(epoch_seconds):
    return time.strftime("%Y-%m-%d", time.localtime(epoch_seconds))
