# A stripped down version of https://github.com/EtienneLem/gauges-events/
# Removed the in-markup event tracking. Added a prefix to allow for segmenting
# events with different trackers.
class GaugesEvents

    constructor: ->
        @_iframe = @_createIframe()

    _createIframe: ->
        iframe = document.createElement('iframe')
        iframe.id = 'gauges-events-tracker'
        iframe.style.cssText = 'width:0;height:0;border:0;visibility:hidden;'
        document.body.appendChild(iframe)
        return iframe

    track: (metric_name, event_data, options) ->
        if params.urls.gauges_events
            event_string = JSON.stringify(event_data)
            event_string = encodeURIComponent(event_string)
            metric_name = encodeURIComponent(metric_name)
            @_iframe.src = "#{ params.urls.gauges_events }?event=#{ metric_name }|#{ event_string }"

module.exports = GaugesEvents