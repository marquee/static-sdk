Proof SDK
=========

The Proof SDK is a set of tools for building reader-facing websites,
often called “frontends”, backed by [Proof](https://proof.pub)-powered
publications. These frontends are compiled into static form — that is, the
output is a simple set of files — for simplicity and speed in serving to
readers.

The front-end for a publication starts with a _compiler_. This compiler takes
content from the Proof API and compiles it into the HTML, CSS, and
JavaScript that make up the reader-facing website. The compiler is intended to
be run whenever the publication’s content has changed, either doing a complete
rebuild, or only parts that have changed content. It also is run whenever the
compiler itself changes and is deployed.

[diagram: Content (API) -> Compiler -> HTML, CSS, JavaScript (S3)]

Changes made to content are _released_, which triggers a webhook to the
_compiler service_. The compiler service then executes the specific compiler.


## Workflow

Much of the SDK is opinionated with regards to workflow, programming
languages, and asset handling, but it does allow for flexibility at a lower
level.

The SDK is optimized around [ES2015+][es2015] and [Sass](sass),
the [CommonJS][commonjs] style of module loading, hosting with
[S3/CloudFront][s3-hosting], and [React](react)-based components. It even
includes a complete suite of components for constructing a typical publication
front-end. However, it does allow for alternative templating and asset
handling, and the output is not tied to a specific host. Also, it is possible
to use the SDK with pure JavaScript and CSS, but this sacrifices some of the
more advanced capabilities.

The SDK is command-line based, and includes a [CLI](../cli/) for building,
development, and deployment.

## Getting started

The [boilerplate project](https://github.com/marquee/frontend-boilerplate) is
a good starting point for projects that use this SDK.


---

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC 2119][rfc2119].


[es2015]: https://babeljs.io/learn-es2015/
[commonjs]: http://commonjs.org/
[react]: http://facebook.github.io/react/
[sass]: http://sass-lang.com
[s3-hosting]: http://docs.aws.amazon.com/gettingstarted/latest/swh/website-hosting-intro.html
[rfc2119]: http://tools.ietf.org/html/rfc2119