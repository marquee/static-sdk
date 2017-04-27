# Compiler

The compiler is a set of functions that compile pure content into markup, or
some other format, for presentation. It is provided with means for accessing
the Marquee Content API, and is executed to generate files to be deployed on
a static site.


## Main

The main compiler function, specified by the `package.main`, is invoked by the
SDK to compile the publication.

The bare minimum for a compiler is the following:

```javascript
module.exports = async function ({ emitFile }) {
    emitFile('/', 'Hello, world!')
}
```

Compilers are “just” JavaScript running on a node platform, and are thus free
to do mostly whatever they need to. However, they SHOULD NOT rely on state
persisted to disk, as they MAY be executed in fresh contexts at arbitrary
times. They MAY make requests to the Marquee Content API, as well as any other
available service.

The main function is given an object as an argument that has various functions
and other information it can use to generate the website.

    api             : api
    emitFile        : _emitFile
    emitRedirect    : _emitRedirect
    emitRSS         : _emitRSS
    emitAssets      : _emitAssets
    config          : project_config
    project         : project_package
    payload         : options.payload
    done            : _done
    info            : build_info

### `api`

The `api` argument is an API wrapper for the Content API initialized with
the project’s token info from its configuration. It provides a method for
loading all of a publication’s content data. Only released content will
be included.

```javascript
const { entries, packages, locations, people, topics } = await api.loadData()
```

The content objects will be normalized, forward references to instances
will be constructed. (ie two entries that point to the same author entity
will point to the same JavaScript Object instance.)

It also provides four methods for retrieving content by type. Note that these
will not normalize.

* `api.entries()`
* `api.packages()`
* `api.channels()`
* `api.posts()`

Each method returns a promise, and also accepts a callback.

```javascript
const [entries, packages] = await Promise.all([
    api.entries()
    api.packages()
])
```

```javascript
api.entries((entries) => {
    ...
})
```



### `config`

The `config` object contains the active configuration for the current build,
including environment, key information, and other project-specific properties.
It is based on, but may vary slightly from, the `marquee` property in the
project’s `package.json` file. See [Configuration](../configuration/) for more
information about how this works.


### `done`

If using the `async` keyword is undesired or impossible, the `done` callback
can be used instead:

```javascript
module.exports = function ({ emitFile, done }) {
    emitFile('/', 'Hello, world!')
    done()
}
```

The `done` function MUST be called when the compiler has finished emitting all
the files necessary. Be sure to call it _after_ asynchronous functions return.
Otherwise, the SDK will move on with the serving or uploading process and
leave some files behind. There is a timeout and the compiler MUST call done
within 30 minutes. If not, it will be killed by the SDK.


### `info`

The `info` object contains the data from the project’s `package.json` file.


### `emitFile`

The `emitFile` function is used to generate the actual files that make up the
site content.

The function takes a file path, and the content of the file:

```javascript
emitFile('index.html', html_content_string)
```

`emitFile` MAY also take a React component and will render it to static markup.

```jsx
emitFile('404.html', <NotFound />)
```

Because React cannot represent the doctype, the output string will have
`<!doctype html>` prepended to it. To emit only a fragment, without the
doctype, set the option `fragment` to `true`:

```jsx
emitFile('fragments/call-to-action.html', <CallToAction />, { fragment: true })
```

For clean URLs, any path that does not end in an extension will output the
file as an `index.html` inside a folder with the given path.

```jsx
emitFile('story-slug', <Story entry={ entry } />)
```

will output a file at `/entry-slug/index.html`.

And

```jsx
emitFile('/', <Home entries={ entries } />)
```

will output a file at `/index.html`.


JSON-serializable objects MAY be given as content, and will be serialized to
a JSON-formatted string.

```javascript
emitFile('data.json', { key: "value" })
```

will output

```json
{"key":"value"}
```


### `emitRedirect`

The `emitRedirect` function allows for creating a 301 redirect from one URL
to another; it’s commonly used when migrating to a new URL structure. It takes
a path or slug like `emitFile` and a URL to redirect to.

```javascript
emitRedirect('/entries/old-slug/', '/articles/new-slug/')
```


### `emitRSS`

A wrapper around `emitFile` that sets RSS-specific a content-type.


### `PRIORITY`

The priority level set by the command that initiated the compilation, defaults
to `Infinity`.

Priority is a way to have granular control over the portions of the site
generated by the compiler. On sites with large amounts of content that don’t
change frequently, those portions can be placed under a priority number.
(The significance of the number is up to the compiler, however the best usage
is with rank priority, 1 being most important, 2 less so, and so on.) This way,
parts of the site that need to be updated right away after a build is triggered
will be updated quickly, while the less important or infrequently changed parts
can be deferred to a later, likely cron-controlled build.

```javascript
if (PRIORITY >= 1) {
    // do less important things
}
```

A useful pattern is to combine priority checks with date, to ensure that
recently modified content is updated.

```javascript
if (PRIORITY >= 2 || NOW - entry.modified_date < ONE_HOUR) {
    // emit entry files
}
```

where `NOW` and `ONE_HOUR` are the current `Date` and the number of milliseconds
in one hour, respectively.


## JSX

The preferred way to author a publication compiler is in
[JSX](http://buildwithreact.com/tutorial/jsx) using [React](http://reactjs.com).
It is not required, but provides for clean, uncrufty code on top of a robust
component architecture.

Regular JavaScript may be used, provided it follows the CommonJS convention and
exports a proper main function. CoffeeScript is also supported.

Most compiled publications are not especially interactive and do not need to
be constructed as a full React-powered client-side application. However, the
strict component-oriented approach provided by React helps organize the
project and improves code reusability. It also provides a starting point that
allows for evolving into a full-fledged React application on the client.

[CJSX](https://github.com/jsdf/coffee-react-transform), the
[CoffeeScript](http://coffeescript.org) variant of the JSX language is also
supported, though that project has been deprecated since October 2016, and
is not recommended.



## Dynamic publications

It is called the Proof _Static_ SDK because the output is intended to be
served in a static way, generally using S3. However, there are ways to
imitate or approximate many dynamic behaviors, like basic search, infinite
scroll, and soft content references.

These features can be implemented in client-side scripts, with the necessary
JSON data baked into JSON files using `emitFile`, or with HTML fragments
instead of full pages. For example, to do search, the compiler can make
by-word indexes of the content using certain fields; the client then performs
the same word normalization, requests the corresponding `<word>.json` files,
and generates the result list. Proper search can also be accomplished with
a search API endpoint, such as the one provided by the Proof content platform.



## Common errors

Some known errors and what causes them.


### “ReferenceError: React is not defined”

Any file that contains JSX or CJSX MUST require React, even if the React
object is never used directly. The compiled JS that the two output uses
React.

See [“React must be in scope”](https://facebook.github.io/react/docs/jsx-in-depth.html#react-must-be-in-scope).


### “Compiler timeout. Compiler MUST call done within 30 minutes.”

Either the compiler does not call `done()` somewhere in its execution, or
the compilation process takes too long. This is required because the compiler
MAY perform asynchronous actions and it needs to tell the SDK that it’s done,
so that the SDK can perform additional actions.

Sometimes, this can show up during development if a compile encountered an
error, then a new file save triggered a fresh compilation.


### “Object has no method apply” or “Cannot call method 'apply' of undefined”

Often shows up when a component is not required properly. The former usually
occurs when a module index is required but not destructured. It either needs
[destructuring](http://coffeescript.org/#destructuring), or a more specific
require. The latter usually occurs when a destructured assignment or export is
misspelled.

This will throw a `Object has no method apply` error when `<Asset>` is used:

```javascript
const Asset = require('proof-sdk/base')
```

vs destructuring or specific require:

```javascript
const { Asset } = require('proof-sdk/base')
// or
const Asset = require('proof-sdk/base/Asset')
```

### Uncommitted changes detected, but no changes apparent

The compiler will halt if uncommitted changes are detected during a deploy, or
only warn if the `--force` flag is used. Sometimes this will happen even when
there aren’t any changes apparent in the project. Make sure there are no
untracked files, and that files such as `.DS_Store` are properly ignored.
(GitX apparently does not show OS X system files like that, even if not
blacklisted by the `.gitignore`.)

Running `git diff-index HEAD && git ls-files --exclude-standard --others` in
the project will show the changes the compiler is seeing.

If `git status` shows no changes, you can probably safely run
`git reset --hard HEAD` to clear this error.

Note: future versions of the SDK may also block deploys if run from a
non-master branch.