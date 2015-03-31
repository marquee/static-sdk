
# General analytics

`marquee-static-sdk/base/analytics`

The SDK provides script snippets for common analytics services, as well as a
wrapper for customized snippets.



## Metrics

In addition to general page-view tracking, a common analytics tool is the
tracking of specific user-initiated events during their time on the page.
Marquee’s SDK provides a client script module called Metric for tracking these
events.

All the built-in components are wired to use the Metric system, and the module
is available for use by any custom client scripts. This allows different
analytics services to be used without having to rewrite the client module to
support a new service. Services can subscribe to these Metrics and receive all
the events that service can support.

The different Metrics can be very specific to the content. For example, the
Block client module provides depth tracking based on block position and
duration of visibility. This reduces the noise caused by rapid scrolling, and
provides depth tracking that’s aware of the content structure. Likewise, the
ImageBlock module tracks user interaction with zoomable images, providing the
specific image zoomed and its position on the page. All Metric events —
built-in and custom — include absolute time-on-page information and, if
supported by the user’s browser, tab focus timing information.


### Built-in

All Metrics include the following properties:

* `_time_on_page` - the time in milliseconds since the user loaded the page
* `_real_time_on_page` - the time in milliseconds since the user loaded
  the page, not including time the tab did not have focus if supported
  by the user’s browser
* `_date` - the Date when the event was fired
* `_ms_since_last` - the number of milliseconds since the last time this
  Metric fired an event


* `Block:seen`
    * Fires the first time an Entry’s content block is visible for at least
      one second.
    * Properties:
        * `depth` - the block order (how many paragraphs, images, embed blocks, etc come before it, plus itself)
        * `percent` - the block order as percentage of total block count
        * `px_top` - the pixel position on page (varies depending on user * screen size and shape)
        * `px_percent` - the pixel position as percentage of page pixels
        * `px_portion` - the pixel height of block as percentage of page pixels
* `ImageBlock:zoom`


### Tracker

Different analytics services support different event payloads. To connect an
analytics service to a Metric, a service- and event-specific Tracker must be
created. This Tracker parses the particular Metric’s event payload into a
format the service supports. The `marquee-static-sdk/trackers` module provides
several base Trackers for common analytics services, such as Google Analytics.

For example, this snippet subscribes a Google Analytics Tracker to the
`Block:seen` event, arranging the parameters in a way supported by Google
Analytics event tracking. It will record an event in Google Analytics the
first time an Entry’s content block is visible for at least one second.

```coffeescript
# Google Analytics requires a parse function since it has a specific format
# for event data: category, action, label, value, non-interaction.
# https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide#Anatomy
Metric.subscribe 'Block:seen', new trackers.GoogleAnalytics (name, event_data) ->
    return ['entry', 'block_seen', entry_params.entry.slug, 1, true]
```

Other services accept unstructured event data, so the subscription is more
simply:

```coffeescript
Metric.subscribe('Block:seen', new trackers.Gauges())
```

Also, a tracker can be subscribed to all Metric events by omitting the event
name:

```coffeescript
Metric.subscribe(new trackers.Gauges())
```

Some service’s libraries may buffer the events into batches, so the requests
being made may not correspond one-to-one with the individual events. The
Metric module itself performs no requests.


### Custom client scripts

(See [Client](./client/) for more information about constructing custom scripts.)

To add support for Metrics inside a custom client script, first require the
`Metric` module:

```coffeescript
Metric = require('marquee-static-sdk/client/Metric')
```

Next, create a Metric for a specific kind of event.

```coffeescript
event_metric = new Metric('ModuleName')
```

Then, whenever that event should be tracked:

```coffeescript
event_metric.track
    arbitrary: 'data' 
```

where the `track()` function is given a JSON serializable Object. The event
will also have the built-in properties described above added automatically.
In addition, the tracker is free to add any additional parameters to the event
when it sends it, such as screen size, user agent strings, etc.

A client script can use as many Metrics as desired, though be mindful of
performance and the user’s experience; if the page has to fire a dozen events
every time the mouse moves or the screen is touched, it could feel sluggish or
run up a bandwidth bill. Well-made Trackers will buffer and batch save events.
