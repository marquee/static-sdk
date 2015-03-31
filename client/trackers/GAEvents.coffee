# https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide
# A parser needs to be defined to turn the event_data into something suitable
# for the Google Analytics tracking. By default, only the metric name is
# included. A parsing function can be provided when initializing the tracker
# instance: new GoogleAnalytics(function(event_data){ return []; });
class GAEvents
    constructor: (@_parse) ->
        unless @_parse
            @_parse = (event_data) -> []
    track: (metric_name, event_data) =>
        ga?('send', 'event', @_parse(metric_name, event_data)...)
    _parse: (event_data) ->
        # 'Entry'
        # 'entry_block_seen'
        # 'story-slug'                  # label
        # 1 or event_data.px_portion    # value
        # false                         # non-interaction
        return []

module.exports = GAEvents