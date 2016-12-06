> This is _pre-release_ software. Unless you work at Marquee, or are one of its clients or partners, you probably should not do anything important with this yet.

Proof SDK
=========
 
[![NPM version](https://badge.fury.io/js/proof-sdk.svg)](http://badge.fury.io/js/proof-sdk) [![Build Status](https://travis-ci.org/marquee/static-sdk.svg)](https://travis-ci.org/marquee/static-sdk)

The Proof SDK is framework for compiling web publications and deploying them into static hosting environments. The SDK as a whole is designed to work with the [Marquee](http://marquee.by) editorial suite and content platform, but parts of it may be used in a standalone fashion.

This package requires [node](https://nodejs.org/) and is distributed through [npm](https://www.npmjs.com/package/proof-sdk/). It assumes a willingness to work in a command line environment and a basic familiarity with node and [git](http://git-scm.com/). Care is taken to keep the learning curve minimal, making projects developed using this SDK accessible to a wide variety of skill sets.


## Technical Overview

The SDK provides components and tools for building _compilers_ that compile structured content and code into HTML, JavaScript, and CSS for front-end presentation of a publication. While not required, the SDK facilitates using [CoffeeScript](http://coffeescript.org/) (specifically [CJSX](https://github.com/jsdf/coffee-react)) and [Sass](http://sass-lang.com/). The compiled output can then be deployed to scalable static hosting providers such as [Amazon S3](http://aws.amazon.com/s3/) and distributed across a content delivery network.

Included in the SDK is a local development server that automatically compiles changes, and an asset pipeline optimized for a [browserify](http://browserify.org/)- and Sass-based workflow that provides minification and hashing in production mode. There is also a set of common components using [React.js](http://facebook.github.io/react/) to generate markup as well as necessary client-side JS and structural styles.

For compilation on content-change, Marquee runs a service that executes per-publication compilers whenever a publication’s content is released. This service also will run a compiler when it receives a git push, providing a way to centralize publication deployments. The Marquee content platform also has a search endpoint that can be used client-side to provide full text search and facilitate more dynamic effects. Additional custom or third party microservices and backends may be used to create a rich, progressively enhanced reader experience.


## Getting Started

Using the Marquee content platform with an requires a **Publication Token** for the corresponding publication. The best way to begin tinkering on a new SDK project is to clone the [sample static project](https://github.com/marquee/sample-static-project) which includes a token for reading from a sample publication. By swapping this read-only token with another token issued through Marquee, the same SDK project could use another publication's content.

_Note:_ the SDK has not been tested on Windows and very likely will not work properly. If Windows support is required, please create an [issue](https://github.com/marquee/static-sdk/issues).


1.  Make sure node and git are installed by running these commands:

    ```sh
    $ node --version
    v4.2.2
    $ git --version
    git version 2.3.1
    ```

    The Static SDK requires at least node `v4.x.x`. If you get a `command not found` error for node, go to [nodejs.org](https://nodejs.org) to download and install node. Generally any version of git should work. If you do not have git, get it [here](http://git-scm.com/).

2.  Create a new directory for your publication and extract the latest release of the sample project:

    ```sh
    $ mkdir <project name> && cd <project name>
    $ curl -L https://github.com/marquee/frontend-boilerplate/tarball/master | tar -zx -C . --strip-components 1
    ```

3.  Start the development server with the following command:

    ```sh
    $ npm run develop
    ```

    Details about the process will scroll down the screen, but when it’s done, you can simply visit [localhost:5000](http://localhost:5000) to view the new project in a browser. It should look something like [this](http://sample-project.marquee.pub/). [View source](view-source:http://localhost:5000/) or poke around in the generated `.dist/` folder of the project to see what the compiler generates.

3.  … make changes, etc

4.  Commit changes to the `develop` branch.

5.  When ready to cut a release

    1. Increment the version number in `package.json` in its own commit, with the comment matching the new version number, eg: `v0.7.2-alpha.3` (you can see the structure of the workflow in the git history)
    2. Merge `develop` into `master` using `--no-ff`: `git merge --no-ff develop`
    3. Create a tag at this merge commit with the version number
    4. Push `develop`, `master`, `--tags`
    5. Run `npm publish` (requires a `env.json` in the Dropbox for deploying docs)