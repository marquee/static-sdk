# CLI

The SDK’s CLI provides a `proof` command for executing builds, a
development server, and deploys. It is installed local to the project. For
convenience, projects usually alias common commands and options using the
npm scripts feature in their `package.json`.

Typical aliases:

* `npm run develop`: `npm install && proof develop --verbose --use-cache`
* `npm run deploy`: `git push origin master && git push proof master`
* `npm run deploy:staging`: `npm install && proof deploy --configuration staging`

Note: the `deploy` command uses a git push. Projects SHOULD NOT be deployed to
production from a local copy if the local branch diverges from the repository
on the compiler service. This can result in incomplete or obsolete builds as
changes to content are made and the compiler service executes builds using an
outdated version of the project.



## Commands


### `build`

Executes a build of assets and runs the compiler.


### `deploy`

Executes a build of assets and runs the compiler in “production” mode. Then,
using the AWS information in the active configuration, uploads the compiler
output to S3. Only added, changed, or deleted files are sent.


### `develop`

Executes a build of assets and runs the compiler, then starts a watcher that
rebuilds assets or reexecutes the compiler as certain files change. Also
starts a simple server for local serving of the compiler output.



## Options


### `--configuration`

Specify a [configuration](../configuration/) to use.

`--configuration <name>` or `-c <name>`


### `--production`

Set the `NODE_ENV` to `'production'`. Defaults to `development` except when
`deploy` is used.

`--production` or `-p`


### `--host`

Set the host for the development server. Defaults to `localhost`. Set to
`0.0.0.0` for testing across a local network: `--host 0.0.0.0`.


### `--port`

Set the port for the development server. Defaults to `5000`: `--port 8080`.


### `--api-cache`

Cache Content API responses to disk for quicker rebuilds during development.
To reset this, run `proof clearcache:api` or simply delete the `.api-cache`
directory from the project folder.


### `--verbose`

Emits detailed information about each step of the build process.


### `--deploy-stats <file>`

Write JSON-formatted stats about the deploy to the specified file.


### `--fake-deploy`

Perform a dry run of the deploy, doing all the compilation and minification in
production mode, but skipping the actual modification of remote files.


### `--batch-size <number:5>`

The number of simultaneous uploads during a deploy.


### `--no-delete`

Skip deleting old remote files. Necessary for partial deploys.


### `--skip-upload-errors`

Only log upload errors during deploy instead of failing completely.


### `--priority <number>`

Set the priority level for the deploy. If set, forces `--no-delete` true.

See [PRIORITY](../compiler/#PRIORITY) for more information.


### `--ignore-schedule`

Ignore any scheduling information on releases.


### `--skip-build-info`

Do not emit build records to `/_build_info/`. By default, the SDK records
(unsensitive) information about the latest builds to `/_build_info/last.json`
and `/_build_info/<priority>.json` which is deployed.


### `--api-page-size <number:100>`

The `?page` parameter used when fetching from the API. This should be adjusted
depending on the typical size of content. Smaller average entry lengths can
use a larger page number, and vice versa.


### `--smart-cache`

Use the `modified_date` property to only fetch content that has changed since
the last deploy (from the instance of the cache).

To reset, run `proof clearcache:smart` or delete the `.smart-cache` folder.

Note: unlike `--api-cache`, this cache does not segregate content based on
endpoint and token. Be careful when using locally and deploying to production!


### `--stale-after <number:1>`

Consider the smart-cache content stale after `n` hours.


### `--build-cache`

Cache builds based on hashes of emits. If `emitFile` is given a string, an
MD5 hash is used. if `emitFile` is given a React component, a hash of the 
props provided is used. If the hash hasn’t changed since the last build, the
file is ignored. This avoids the overhead of React’s `renderToStaticMarkup`.
The asset hash is also cached.

This caching assumes the remote files have not been manipulated by another
build. It should only be used in a production CI setup. Changes in git sha
will invalidate the cache.

To reset, run `proof clearcache:build` or delete the `.build-cache` folder.



