# Assets

The Marquee Static SDK asset workflow leans heavily on [Sass](http://sass-lang.com/)
and [Browserify](http://browserify.org/), though neither tool is required.

JavaScript, CSS, and images go in the `assets/` folder, and are automatically
included in the build output, with some processing. All `.js`, `.css`, and
image files are copied as-is. A `script.coffee` file is compiled, with
Browserify, and output as `script.js`. A `style.sass` file is compiled and
output as `style.css`. Other `.coffee` and `.sass` files are not directly
copied over, but available for `require` or `@import`. They also may be used
by the `<Asset>` component. Any files in a tree that starts with a `.` or `_`
are ignored.

All `.js` and `.css` files, and the output of `.coffee` and `.sass` files, are
minifed when building with the `--production` flag, and gzipped when deployed.
Production builds also will hash the compiled assets and use that for URLs
to bust caches.


## Style & script entrypoints

The preferred way to load styles and scripts into the page is through one
entrypoint for styles and one for scripts. Different modules are then included
using `@import` or `require` as appropriate. The entrypoints are each bundled
into single files by the build, using `sass` and `browserify`.

To take advantage of caching, the entire site SHOULD use one stylesheet and
one script bundle for all pages. Script modules are activated as necessary
on each page.


## `<Asset>`

The `<Asset>` component is used to include assets in the rendered page, either
by reference or inline. The component will generate the correct markup, and
when building for production, include the cache-busting hash in the path. The
files are relative to the `assets/` source folder. The component will ensure
the asset is copied over.

    <Asset path='style.sass' />
    <Asset path='script.coffee' async=true />
    <Asset path='base.coffee' />

To inline scripts or styles into the page, set the prop `inline=true`:

    <Asset path='base.coffee' inline=true />

This will compile the specified file, using browserify, and inline the bundle
into the page (minified with `--production` or a deploy). Inlining is useful
for critical styles, or a script like `elementQuery` used to adjust the
layout, which should be included with the first request for the page.

## `includeAssets`


Assets that are not automatically processed and not handled by an `<Asset>`
can be included directly.

    includeAssets('tenant_theme.sass', 'page_specific_script.coffee')

