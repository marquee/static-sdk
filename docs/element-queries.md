# Element Queries

[Element queries](http://css-tricks.com/use-cases-requirements-element-queries/)
are a way to have CSS rules apply to an element based on its size. Using
element queries requires defining them in the styles, and including a polyfill
snippet of JavaScript that manipulates the elements to add attribuets matching
the selectors in the CSS.

The Marquee Static SDK includes a forked version of the
[elementQuery](https://github.com/tysonmatanich/elementQuery) polyfill, and
some Sass helpers, for using them on projects. (Note: this fork only supports
px values.)



## Stylesheets

To define the element query rules, the following mixins are available from
`@import "marquee"`:

```sass
+eq-width-gt($px_value)
+eq-width-gt-extra_small
+eq-width-gt-small
+eq-width-gt-medium
+eq-width-gt-large
+eq-width-gt-extra_large
```

For example:

```sass
.SomeComponent
    font-size: 12px
    +eq-width-gt-extra_small
        font-size: 16px
```

The resulting CSS:

```css
.SomeComponent {
    font-size: 12px;
}
.SomeComponent[min-width~="641px"] {
    font-size: 16px;
}
```

Whenever the width of an element matching the `.SomeComponent` class is
`641px` or greater, it will have a `font-size` of `16px`.

There mixins have height equivalents, which work the same but query the
element’s height. There are `gte`, `lt`, `lte` versions as well, though the
recommended usage is to start with the smallest size and work up.

The sizes default to these values, and can be adjusted by overriding the
variables in `_config.sass`:

```sass
$break-extra_small : 640px
$break-small       : 768px
$break-medium      : 1024px
$break-large       : 1280px
$break-extra_large : 1440px
```

## `<ElementQuery />`

For the element queries to take effect in the page, a bit of JavaScript needs
to be included. Adding `<ElementQuery />` will activate all the element
queries in `style.sass`, and (re-)apply them as necessary. If there are
multiple style entry points, they can be specified using the `styles` prop:

    <ElementQuery styles='critical.sass' />

or

    <ElementQuery styles=['critical.sass', 'screen.sass'] />

More than one `<ElementQuery>` component can be used, though it will duplicate
the included engine script in the page.

Instead of being a requirable module, this is provided as a component for
a couple reasons. The component parses the stylesheets for the element query
selectors and includes the parsed form with the engine at render time. The
generated output is ready to take effect immediately. Also, since it is
potentially essential to the layout, it works best when inlined into the
rendered page.
