# Facebook Instant Articles

The Marquee Static SDK has built-in components to support Facebook’s
[Instant Articles](https://instantarticles.fb.com/) program. Instant Articles
works by ingesting article content from a single RSS feed. To create this feed,
use the `emitRSS` file emitter and the `fbInstantArticlesRSSFeed` renderer.

In the project’s `main`:

```javascript
var fbInstantArticlesRSSFeed = require('proof-sdk/fb_instant_articles/fbInstantArticlesRSSFeed');
```

```
emitRSS(
    'fb_instant_feed.xml',
    fbInstantArticlesRSSFeed({
        entries: list_of_entries
    })
);
```

Then, configure the publication on Facebook to point to
`http://<hostname>/fb_instant_feed.xml`. The look-and-feel can also be
customized through the interface on Facebook.

A would-be-nice is to include the Marquee-related OG tags for the IA program in
the `<head>` of the project’s `<Base>`:

```jsx
var fb_generator_tags = require('proof-sdk/fb_instant_articles/fb_generator_tags');

...

    render: ->
        <html>
            <head>
                ...
                { fb_generator_tags }
                ...
```

The FB system only accepts up to 100 articles, so the `list_of_entries` should
consist of the 100 most recent Entries that are to be distributed through IA.