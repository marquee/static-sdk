# Elements


## Base

`marquee-static-sdk/base` includes a set of React elements for lower level
page elements, typically ones that aren’t visible in the page.

### Analytics

The Analytics module contains several elements for including tracking snippets
for different analytics services.

* GoogleAnalytics
* ChartbeatStart
* Chartbeat
* Guages

### Asset

For including JavaScript and CSS, either by reference or inline.

### BuildInfo

Includes some metadata about the project at build time in JSON format,
including:

* current commit sha
* asset hash
* build date

### ElementQuery

Enables using element queries in the styles. Parses the stylesheets for
element query selectors, and includes the script necessary to activate them
in the client.

See [ElementQuery](./elementqueries/) for details.

### Favicon

Includes a link to the favicon, setting the correct type.

### GoogleFonts



### JSONData


### makeMetaTags

A function that generates an Array of `<meta>` tags from a given object.
(Not a React component since it needs to return more than one tag at a time.)



## Components

A set of React components

### Byline

### Card

### Category

### Cover

### CoverCredit

### DateTime

### Info

### Summary

### Tags

### Title