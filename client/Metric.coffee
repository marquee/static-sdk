# Metrics provide in-page event tracking, like a user interacting with the 
# image zoomer or scrolling through the HomeStream. Each module can and should
# initialize its own Metric to track: metric = new Metric('Name'). Individual
# trackers for each service then subscribe to Metrics and track the events
# however they need to.
#
#     metric = new Metric('ModuleName')
#     metric.track({ event_data }) or metric.track(key, value)
#
class Metric

    # Global subscriptions, since each Metric must also fire on '*'.
    _subscriptions = {}

    constructor: (name='*') ->
        @_name = name
        @_last_tracked = null

    # Can take either a key/value pair, or an object.
    track: (event_data_or_key, value=null) =>

        # Skip preparing the track if nothing is subscribed.
        unless _subscriptions[@_name] or _subscriptions['*']
            return

        if typeof event_data_or_key is 'object'
            event_data = event_data_or_key
        else
            event_data = {}
            if event_data_or_key
                event_data[event_data_or_key] = value

        # Add timing info to event data.
        event_data._time_on_page        = time_on_page
        event_data._real_time_on_page   = real_time_on_page
        event_data._date                = new Date()

        # Include the ms count since the last event of this Metric. `null` if
        # it is the first.
        if @_last_tracked?
            event_data._ms_since_last = event_data._date - @_last_tracked
        else
            @_last_tracked = event_data._date
            event_data._ms_since_last = null

        @_fire(@_name, event_data)
        # Trackers must opt-in specifically to Metrics prefixed with `_`.
        @_fire('*', event_data) unless @_name is '*' or @_name[0] is '_'

    _fire: (metric_name, event_data) ->
        _subscriptions[metric_name]?.forEach (tracker) =>
            if tracker.track?
                tracker.track(@_name, event_data)
            else
                tracker(@_name, event_data)

    # Trackers can subscribe to specific metrics, or any using 
    # Metric.subscribe(tracker) or Metric.subscribe('*', tracker)
    # The trackers can be an object that has a track method, or a function.
    @subscribe = (metric_name, tracker) ->
        if metric_name and not tracker
            tracker = metric_name
            metric_name = '*'
        _subscriptions[metric_name] ?= []
        _subscriptions[metric_name].push(tracker)

    @getTimeOnPage = -> time_on_page
    @getRealTimeOnPage = -> real_time_on_page


    # Internal Metrics

    # Only activate if being executed in the context of a page.
    if document?
        # Track time on page overall, and time page has focus. If time_on_page is -1
        # when tracked, the client does not support checking if it has focus.
        time_on_page = if document.hasFocus? then 0 else -1
        real_time_on_page = 0

        # Use the Chartbeat page load reference point if present.
        last_tick = window._sf_startpt or (new Date()).getTime()

        # Built-in Metrics for time-on-page.
        time_on_page_metric = new Metric('_time_on_page')
        real_time_on_page_metric = new Metric('_real_time_on_page')

        # Every 1s, update the time counts.
        time_on_page_clock = setInterval ->
            now = (new Date()).getTime()
            ms_delta = now - last_tick
            real_time_on_page += ms_delta

            # Include the delta when tracking for trackers like Google Analytics
            # which do cumulative tracking per-session.
            real_time_on_page_metric.track(delta: ms_delta)

            # Track time the page has focus separately. This way the actual attention
            # can be recorded, versus when the page is open in a tab or the browser
            # itself does not have focus.
            if document.hasFocus?()
                time_on_page += ms_delta
                time_on_page_metric.track(delta: ms_delta)

            last_tick = now
        , 1000


module.exports = Metric
