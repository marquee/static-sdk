# A stripped down version of https://github.com/EtienneLem/gauges-events/
# Removed the in-markup event tracking. Added a prefix to allow for segmenting
# events with different trackers.
class module.exports.Gauges

    constructor: ->
        @_iframe = @_createIframe()

    _createIframe: ->
        iframe = document.createElement('iframe')
        iframe.id = 'gauges-events-tracker'
        iframe.style.cssText = 'width:0;height:0;border:0;visibility:hidden;'
        document.body.appendChild(iframe)
        return iframe

    track: (metric_name, event_data) ->
        if params.urls.gauges_events
            event_string = JSON.stringify(event_data)
            event_string = encodeURIComponent(event_string)
            metric_name = encodeURIComponent(metric_name)
            @_iframe.src = "#{ params.urls.gauges_events }?event=#{ metric_name }|#{ event_string }"

# Variant of GaugesEvents
class module.exports.Logevents

    constructor: ->
        @_iframe = @_createIframe()

    _createIframe: ->
        iframe = document.createElement('iframe')
        iframe.id = 'logevents-tracker'
        iframe.style.cssText = 'width:0;height:0;border:0;visibility:hidden;'
        document.body.appendChild(iframe)
        return iframe

    track: (metric_name, event_data) ->
        if params.urls.logevents
            event_string = JSON.stringify(event_data)
            event_string = encodeURIComponent(event_string)
            metric_name = encodeURIComponent(metric_name)
            @_iframe.src = "#{ params.urls.logevents }?event=#{ metric_name }|#{ event_string }"



# https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide
# A parser needs to be defined to turn the event_data into something suitable
# for the Google Analytics tracking. By default, only the metric name is
# included. A parsing function can be provided when initializing the tracker
# instance: new GoogleAnalytics(function(event_data){ return []; });
class module.exports.GoogleAnalytics
    constructor: (@_parse) ->
        unless @_parse
            @_parse = (event_data) -> []
    track: (metric_name, event_data) =>
        _gaq?.push([
                '_trackEvent'
                @_parse(metric_name, event_data)...
            ])
    _parse: (event_data) ->
        # 'Entry'
        # 'entry_block_seen'
        # 'story-slug'                  # label
        # 1 or event_data.px_portion    # value
        # false                         # non-interaction
        return []

###
Metric.subscribe(new Analytics.Gauges());

# Google Analytics requires a parse function since it has a specific format
# for event data: category, action, label, value, non-interaction.
# https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide#Anatomy

# The following will record an event the first time an entry content block is
# visible for at least one second.
Metric.subscribe('Block',
    new Analytics.GoogleAnalytics(
        function(name, event_data){
            return ['entry', 'block_seen', entry_params.entry.slug, 1, true]
        }
    )
);
###