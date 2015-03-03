Marquee Static SDK
==================

> This is pre-release software. Unless you work at Marquee, or are one of its clients or partners, you probably should not do anything important with this.

The Marquee Static SDK is framework for compiling web publications and deploying them into static hosting environments. Typically, these web publications tend to managed by an [editorial suite](http://marquee.pub/editorial) and [content platform](http://marquee.pub/platform) for clients of [Marquee](http://marquee.pub); but, it may also be used in a completely standalone nature.

This package is distributed through [`npm`](https://www.npmjs.com/package/marquee-static-sdk) and assumes a willingness to work in a command line environment. Care is taken to keep the learning curve minimal, making projects developed using this SDK accessible to a wide variety of skill sets.

## Technical Overview

The SDK is designed to compile projects developed in CoffeeScript and Sass into static assets. These assets can then be deployed to scalable static hosting providers such as [Amazon S3](http://aws.amazon.com/s3) and distributed across a content delivery network. 

[React.js](http://facebook.github.io/react/) components defined using [CJSX](https://github.com/jsdf/coffee-react) are combined into HTML by a compiler script located within each SDK project. These components may reference interaction and style assets generated from vanilla CoffeeScript and Sass sources.

The compiler script will pull published content through the Marquee API and iterate over the results, creating files for individual entries, index pages, and content streams along the way. Content is modeled as JSON, which can be manipulated and rendered as necessary. 

The SDK provides a local development server, watches for changes to a project's source files, includes components for common patters, and integrates deployment to S3. Each time a change to the code base is pushed or content is updated through the Editorial Suite, the entire site is regenerated and replaced on S3.

In instances where live or server-side processing is required, client-side scripting can be used in conjunction with any variety of microservices to achieve much of functionality traditionally delivered through a web application architecture. This pattern enforces a clear separation of concerns, improves maintain ability, encourages iteration, enhances security, and is more efficiently scalable. Properly built static websites are awesome.

## Getting Started

The best way to begin tinkering on a new SDK project is to clone the [Static SDK Boilerplate](http://github.com/marquee/static-sdk-boilerplate) which includes a **Publication Token** for interacting with a sample repository hosted on the Content Platform. By swapping this read-only token with another token issues through Marquee, the same SDK project could use another publication's content.

Run the following from the command line, substituting `<project_name>` for the name of your project. For your own sanity, the project name should not include spaces or capital letters. 

```
$ git clone git@github.com/marquee/static-sdk-boilerplate <project_name>
$ cd <project name>
```

The first command will clone the boilerplate project into the project's directory; and the second command changes into that directory.

To run the development server, you must simply run the following command:

```
$ npm run develop
```

Details about the process will scroll down the screen, but when it's done, you can simply visit http://localhost:5000 to view the new project in a browser.