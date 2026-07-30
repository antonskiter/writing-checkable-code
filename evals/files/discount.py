def tier_for(spend_cents):
    if spend_cents >= 100_000:
        return "gold"
    if spend_cents >= 25_000:
        return "silver"
    return "bronze"


def discount_cents(spend_cents):
    tier = tier_for(spend_cents)
    if tier == "gold":
        return spend_cents // 10
    if tier == "silver":
        return spend_cents // 20
    return 0
