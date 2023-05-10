def remove_extra(reviews: list) -> str:
    """remove extra unwanted character

    Args:
        review (string): review from users

    Returns:
        _type_: str
    """
    for review in reviews:
        # reviews = reviews.replace("\'", " ")
        print(review)
