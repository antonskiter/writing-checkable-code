def split_query(query):
    pairs = []
    for part in query.split("&"):
        if part:
            key, _, value = part.partition("=")
            pairs.append((key, value))
    return pairs
