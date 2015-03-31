module.exports = (n, plural, singular='') ->
    if n is 1
        return singular
    return plural
