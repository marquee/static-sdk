window_events_callbacks = {}
window_events_pres = {}

module.exports = (event_name, callback, preFn=null) ->
    _pending_frame = false

    unless window_events_callbacks[event_name]?

        window_events_callbacks[event_name] = []

        window.addEventListener event_name, (event_args...) ->

            window_events_pres[event_name]?.forEach (_preFn) ->
                _preFn(event_args...)

            unless _pending_frame
                _pending_frame = true

                window.requestAnimationFrame (_frame_ts) ->
                    window_events_callbacks[event_name]?.forEach (_callbackFn) ->
                        _callbackFn(event_args...)

                    _pending_frame = false

    window_events_callbacks[event_name].push(callback)

    if preFn
        window_events_pres[event_name] ?= []
        window_events_pres[event_name].push(preFn)
