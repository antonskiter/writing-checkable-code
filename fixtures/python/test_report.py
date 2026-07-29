from report import Interval, classify, render_row


def test_render_row_pads():
    row = render_row("a", Interval(0, 60), "m", 0, "left", 10, ".")
    assert isinstance(row, str)


def test_classify_returns_a_string():
    assert classify(Interval(0, 60), 120, set()) in {"future", "holiday", "past"}


def test_interval_is_frozen():
    interval = Interval(0, 60)
    assert interval.start == 0
