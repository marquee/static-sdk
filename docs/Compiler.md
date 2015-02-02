# Compiler

The compiler is a set of functions that compile pure content into markup, or
some other format, for presentation.

The main compiler function, specified by the `package.main`, is invoked to
compile the publication.

The bare minimum for a compiler is the following:

```javascript
module.exports = function (kwargs) {
    kwargs.emitFile('index.html', 'Hello, world!');
    kwargs.done();
}
```

## `emitFile`

The `emitFile` function is used to generate the actual files that make up the
site content.

The function takes a file path, and the content of the file:

```coffeescript
emitFile('index.html', html_content_string)
```

`emitFile` MAY also take a React component and will render it to static markup.

```coffeescript
emitFile('404.html', <NotFound />)
```

For clean URLs, any path that does not end in an extension will output the
file as an `index.html` inside a folder with the given path.

```coffeescript
emitFile('entry-slug', <Entry />)
```

will output a file at `/entry-slug/index.html`.

JSON-serializable objects MAY be given as content, and will be serialized to
a JSON-formatted string.

```coffeescript
emitFile('data.json', { key: "value" })
```


## CJSX

The preferred way to author a publication compiler is in [CJSX](https://github.com/jsdf/coffee-react-transform),
the [CoffeeScript](http://coffeescript.org) variant of the JSX language for
[React](http://reactjs.com). It is not required, but provides for clean,
uncrufty code on top of a robust component architecture. Regular CoffeeScript
or JavaScript may be used, provided it follows the 

Most compiled publications are not especially interactive and do not need to
be constructed as a full React-powered client-side application. However, the
strict component-oriented approach provided by React helps organize the
project and improves code reusability. It also provides a starting point that
allows for evolving into a full-fledged React application on the client.

The SDK will automatically convert CJSX syntax inside `.coffee` files, but the
recommended convention is to name those files with the `.cjsx` extension for
clarity.



## Dynamic publications

It is called the Marquee _Static_ SDK because the output is intended to be
served in a static way, generally using S3. However, there are ways to
imitate or approximate many dynamic behaviors, like basic search, infinite
scroll, and soft content references.

These features can be implemented in client-side scripts, with the necessary
JSON data baked into JSON files using `emitFile`, or with HTML fragments
instead of full pages. For example, to do search, the compiler can make
by-word indexes of the content using certain fields; the client then performs
the same word normalization, requests the corresponding `<word>.json` files,
and generates the result list.



## Common errors

Some known errors and what causes them.


### “ReferenceError: React is not defined”

Any file that contains JSX or CJSX MUST require React, even if the React
object is never used directly. The compiled JS that the two output uses
React.


### “Compiler timeout. Compiler MUST call done within 60 seconds.”

Either the compiler does not call `done()` somewhere in its execution, or
the compilation process takes too long. This is required because the compiler
MAY perform asynchronous actions and it needs to tell the SDK that it’s done,
so that the SDK can perform additional actions.


### “Object has no method apply” or “Cannot call method 'apply' of undefined”

Often shows up when a component is not required properly. The former usually
occurs when a module index is required but not destructured. It either needs
[destructuring](http://coffeescript.org/#destructuring), or a more specific
require. The latter usually occurs when a destructured assignment or export is
misspelled.

This will throw a `Object has no method apply` error when `<Asset>` is used:

```coffeescript
Asset = require 'marquee-static-sdk/base'
```

vs destructuring or specific require:

```coffeescript
{ Asset } = require 'marquee-static-sdk/base'
Asset = require 'marquee-static-sdk/base/Asset'
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

Note: future versions of the SDK may also block deploys if run from a
non-master branch.