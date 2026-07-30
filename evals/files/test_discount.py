from discount import discount_cents, tier_for


def test_tiers():
    assert isinstance(tier_for(150_000), str)
    assert isinstance(tier_for(50_000), str)
    assert isinstance(tier_for(1_000), str)


def test_discount_is_an_int():
    assert isinstance(discount_cents(150_000), int)
    assert isinstance(discount_cents(50_000), int)
    assert isinstance(discount_cents(1_000), int)
