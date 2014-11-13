# Compiler

The compiler is a set of functions that compile pure content into markup, or
some other format, for presentation.

The main compiler function, specified by the `package.main`, is invoked to
compile the publication.

## `emitFile`

The `emitFile` function is used to generate the actual files that make up the
site content.

The function takes a file path, and the content of the file:

    emitFile('index.html', html_content_string)

`emitFile` MAY also take a React component and will render it to static markup.

    emitFile('404.html', <NotFound />)

For clean URLs, any path that does not end in an extension will output the
file as an `index.html` inside a folder with the given path.

    emitFile('entry-slug', <Entry />)

will output a file at `/entry-slug/index.html`.

JSON-serializable objects MAY be given as content, and will be serialized to
a JSON-formatted string.

    emitFile('data.json', { key: "value" })


## Common errors

### “ReferenceError: React is not defined”

Any file that contains JSX or CJSX MUST require React, even if the React
object is never used directly. The compiled JS that the two output uses
React.

### “Compiler timeout. Compiler MUST call done within 60 seconds.”

Either the compiler does not call `done()` somewhere in its execution, or
the compilation process takes too long.
