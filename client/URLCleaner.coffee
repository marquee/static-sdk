module.exports = ->
    # Clean analytics parameters from URL, for a nice, clean feeling. Also, keeps
    # people from sharing URLs that were tracking specific sources and skewing the
    # stats. Based on: http://wistia.com/blog/fresh-url
    # `utm` parameters are used by Google Analytics and others, as well as
    # internal reference tracking.

    # Remove any parameters that start with `utm_` using replaceState.
    _stripParameters = ->
        if window.history?.replaceState?
            cleaned_search = window.location.search.replace(/utm_[^&]+&?/g, '').replace(/&$/, '').replace(/^\?$/, '')
            window.history.replaceState({}, '', window.location.pathname + cleaned_search)
        return

    # Google Analytics is present, so add the strip function to its queue
    # so it can extract the data it needs first.
    if window._gaq?
        window._gaq.push(_stripParameters)
    else
        _stripParameters()
