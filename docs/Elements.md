# Elements

The Marquee Static SDK includes a library of components for constructing a
compiler. They are React-based, and are best used with CJSX. Included are
base components, cards, subcomponents for various parts of the entries, and------

You can try CJSX syntax live http://jsdf.github.io/coffee-react-transform/

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

See [Assets](./assets/) for details about the asset workflow.


### BuildInfo

Includes some metadata about the project at build time in JSON format,
including:

* current commit sha
* asset hash
* build date

If the build was done while the git tree was dirty, the sha will have a
`-dirty` suffix.


### ElementQuery

Enables using element queries in the styles. Parses the stylesheets for
element query selectors, and includes the JavaScript necessary to activate
them in the client.

See [ElementQuery](./elementqueries/) for details.


### Favicon

Includes a link to the favicon, setting the correct type.


### GoogleFonts



### JSONData

Include the given JSON-serializable object as raw JSON data available to
scripts in the page.


### makeMetaTags

A function that generates an Array of `<meta>` tags from a given object.
(Not a React component since it needs to return more than one tag at a time.)



## Components

A set of React components

### Byline

A component for displaying one or more byline names.

```cjsx
<Byline byline='Author Name' />
```

Two names are separated by an and word, defaulting to `&` and configurable
using the `and='&'` prop.

```cjsx
<Byline byline={['Author Name', 'Other Author']} and='and' />
```

If there are three or more names, they are joined using a comma. This can be
changed using the `join=', '` prop.

```cjsx
<Byline byline={['Author Name', 'Other Author', 'Third Collaborator']} />
```

Yes, it only supports an Oxford comma.

### Card

### Category

### Cover

### CoverCredit

### DateTime

### Info

### Summary

### Tags

### Title