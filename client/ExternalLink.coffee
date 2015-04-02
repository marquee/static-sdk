Metric = require './Metric'

module.exports =
    activate: ({ host, newtab, selector_prefix, intercept }) ->
        newtab          ?= false
        selector_prefix ?= ''
        intercept       ?= false

        metric = new Metric('ExternalLink')

        for link in document.querySelectorAll("#{ selector_prefix } a[data-external='true']")
            do ->
                _link = link
                _link.setAttribute('target', '_blank') if newtab
                _link.addEventListener 'click', (e) ->
                    if intercept
                        e.preventDefault()
                        postTrack = ->
                            window.location = _link.href
                    metric.track
                        url: _link.href
                    , null,
                        callback: postTrack

require('./client_modules').register('ExternalLink', module.exports)
