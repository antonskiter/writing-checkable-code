from dataclasses import dataclass


@dataclass(frozen=True)
class Interval:
    """Half-open [start, end) in whole minutes since midnight."""
    start: int
    end: int


def render_row(label, interval, unit, precision, align, width, fill):
    span = interval.end - interval.start
    text = f"{span:.{precision}f}{unit}"
    if align == "right":
        return (label + text).rjust(width, fill)
    return (label + text).ljust(width, fill)


def classify(interval, now, holidays):
    if interval.end <= interval.start:
        raise ValueError(f"interval ends before it starts: {interval}")
    if interval.start > now:
        return "future"
    if interval.start in holidays:
        return "holiday"
    return "past"
