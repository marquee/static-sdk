# Elements

The Marquee Static SDK includes a library of components for constructing a
compiler. They are React-based elements, best used with CJSX. Included are
base components, cards, subcomponents for various parts of the entries and the
rest of a content site.

You can try CJSX syntax live: http://jsdf.github.io/coffee-react-transform/



## Base

`marquee-static-sdk/base` includes a set of React elements for lower level
page elements, typically ones that aren’t visible in the page.


### analytics

`marquee-static-sdk/base/analytics`

The Analytics module contains several elements for including tracking snippets
for different analytics services.

* GoogleAnalytics
* ChartbeatStart
* Chartbeat
* Gauges


### Asset

For including JavaScript and CSS, either by reference or inline.

See [Assets](../assets/) for details about the asset workflow.


### BareBase

A barebones base element providing just enough markup for a complete HTML
document.

```cjsx
<BareBase
    title       = 'page title'
    className   = 'BodyClass'
>
    {page_content}
</BareBase>
```

### Base

A more complete base element including common elements such as Favicon, script
and style entry point assets, and a nav, content, and footer structure.

Most projects will require a customized base, but this element is provided
as a starting point for development use, and makes a suitable template to copy.


### BuildInfo

Includes some metadata about the project at build time, including:

* current commit sha
* asset hash

The metadata will be available under `window.Marquee.build_info`.

This info is useful for including in a [Tracker](../analytics/) to group events
by site version. If the build was done while the git tree was dirty, the sha
will have a `-dirty` suffix.


### ElementQuery

Enables using element queries in the styles. Parses the stylesheets for
element query selectors, and includes the JavaScript necessary to activate
them in the client.

See [ElementQuery](../element-queries/) for details.


### Favicon

Includes a link to the favicon, setting the correct type. Defaults to
`./favicon.ico` in `/assets/`.


### Fragment

Wrapper for creating HTML fragments. These SHOULD be emitted using the
`fragment: true` option on `emitFile`.


### GoogleFonts

A tag for loading Google Fonts-hosted webfonts.

```cjsx
<GoogleFonts fonts={
    'Raleway': [400,700]
}/>
```



### JSONData

Include the given JSON-serializable object as raw JSON data available to
scripts in the page.


### makeMetaTags

A function that generates an Array of `<meta>` tags from a given object.
(Not a React component since it needs to return more than one tag at a time.)



## Components

A set of React components and subcomponents for constructing customized cards
or other components.


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


### Card

The base of a typical Card. Can be made a link.

```cjsx
<Card>{card_content}</Card>
```

```cjsx
<Card link=entry.link>{card_content}</Card>
```


### Category

Category subcomponent.

```cjsx
<Category category=entry.category />
```


### CoverImage

CoverImage component for cover images. Can be made a link.

```cjsx
<CoverImage image=entry.cover_image />
```

```cjsx
<CoverImage image=entry.cover_image link=entry.link />
```

The CoverImage requires 'marquee-static-sdk/client/CoverImage' to be loaded
in the client modules, which selects the correct image resolution based on
available size and screen resolution, as well as image visibility. Or, the
`<CoverImage>` can be used directly in a live React app, and will perform the
necessary checks and image selection.




### CoverCredit


### DateTime

A component for displaying `Date` objects. Uses [moment.js][momentjs] for
formatting.

```cjsx
<DateTime date=entry.display_date format='MM/DD/YYYY' />
```

The `DateTime` supports a label prop to be included next to the date string. It
also supports moment’s relative formatting.

```cjsx
<DateTime date=entry.display_date relative=true />
```

The relative prop can be set to only apply if the value is within a certain
number of days or hours. When outside the range, the given format (or default)
is used.

```cjsx
<DateTime date=entry.display_date relative={days: 7} format='YYYY M D' />
```

```cjsx
<DateTime date=entry.display_date relative={hours: 2} />
```

The `title` attribute of the element includes the date value, and will be
formatted according to the specified `title_format`.

### Info

A grouping subcomponent used to group other subcomponents inside a Card or
Cover.


### Summary


### Tags

A tags component that renders arrays of tags.

```cjsx
<Tags tags={[
    { name: 'Some Tag', slug: 'some-tag'}
]} />
```

### Title

A title subcomponent using heading elements. Variable levels, defaults to `h3`.
Can be made a link.

```cjsx
<Title title=entry.title />
```

```cjsx
<Title title=entry.title level=2 link=entry.link />
```


## Layouts

### CardGrid

A grid that has one, two, or three columns. Requires importing the styles from
`marquee/layouts` (or `marquee/classes`). Also requires using
[ElementQuery](../element-queries/).

```cjsx
<CardGrid columns=2>
    { items }
</CardGrid>
```

If `vary` is set, the number of columns will adjust as space allows, up to the
`columns` set.

```cjsx
<CardGrid columns=3 vary=true>
    { items }
</CardGrid>
```

`double_first=true` will make the first cell the width of two columns, useful
for featured cards.

```cjsx
<CardGrid columns=2>
    { items }
</CardGrid>
```

By default, the `CardGrid` responds to its own width using element query. It
can also respond to the viewport using `respond_to_viewport=true`.

```cjsx
<CardGrid columns=3 respond_to_viewport=true>
    { items }
</CardGrid>
```




[momentjs]: http://momentjs.com/docs/#/displaying/