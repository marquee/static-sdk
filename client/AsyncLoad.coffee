Metric                          = require 'marquee-static-sdk/client/Metric'

AGENT_IS_MOBILE                 = require './utils/AGENT_IS_MOBILE'
getElPositionAndSize            = require './utils/getElPositionAndSize'
listenToThrottledWindowEvent    = require './utils/listenToThrottledWindowEvent'
makeRequest                     = require './utils/makeRequest'

LOADED      = 'loaded'
LOADING     = 'loading'
READY       = 'ready'
VISIBLE     = 'visible'

callbacks   = {}
metric      = null
on_visible  = []

DEBUG ?= false


loadEl = (el, url=null, callback=null) ->
    url         ?= el.dataset.asyncload_url
    callback    ?= el._AsyncLoad_callback

    el.dataset.asyncload = LOADING
    console.info("AsyncLoad: loading #{ url }") if DEBUG

    makeRequest url, (fragment) ->
        el.innerHTML = fragment
        el.dataset.asyncload = LOADED
        console.info("AsyncLoad: loaded #{ url }") if DEBUG

        callback?()
        callbacks.load?.forEach (cb) -> cb()

        if el.dataset.asyncload_track
            metric.track
                fragment: url


setUpLoadOnVisible = ->
    win_y = 0
    win_h = 0

    _checkVisibility =  ->
        # 2x window height so it starts to load _before_ it's visible. 3x for
        # mobile since it doesn't fire events until the scroll stops.
        if AGENT_IS_MOBILE
            buffer_size = win_h * 3
        else
            buffer_size = win_h * 2
        threshold = win_y + (buffer_size)
        on_visible.forEach (el) ->
            if el.dataset.asyncload is READY and getElPositionAndSize(el).top < threshold
                loadEl(el)

    listenToThrottledWindowEvent 'scroll', _checkVisibility, ->
        win_y = window.scrollY
        win_h = window.innerHeight


init = ->

    target_els = document.querySelectorAll('[data-asyncload_url]')
    for el in target_els
        do ->
            _el = el
            _el.dataset.asyncload = READY
            if _el.dataset.asyncload_on is VISIBLE
                on_visible.push(_el)
            else
                loadEl(_el)
    setUpLoadOnVisible(on_visible)
    metric = new Metric('AsyncLoad')

init.loadInto = loadEl

init.loadIntoOnVisible = (el, url, callback=null) ->
    el.dataset.asyncload        = READY
    el.dataset.asyncload_url    = url
    el._AsyncLoad_callback      = callback
    on_visible.push(el)

init.on = (ev_name, callback) ->
    callbacks[ev_name] ?= []
    callbacks[ev_name].push(callback)

init.off = (ev_name, callback=null) ->
    if callback
        if callbacks[ev_name]
            i = 0
            for cb in callbacks[ev_name]
                if cb is callback
                    break
                i += 1
            callbacks[ev_name] = [
                callbacks[ev_name][...i]...
                callbacks[ev_name][i+1...]...
            ]
    else
        callbacks[ev_name] = []

module.exports = init
require('marquee-static-sdk/client/client_modules').register(
    'AsyncLoad', module.exports)
