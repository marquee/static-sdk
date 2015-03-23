# CLI

The SDK’s CLI provides a `marqueestatic` command for executing builds, a
development server, and deploys. It is installed local to the project. For
convenience, projects usually alias common commands and options using the
npm scripts feature in their `package.json`.

Typical aliases:

* `npm run develop`: `npm install && ./node_modules/.bin/marqueestatic develop --verbose --use-cache`
* `npm run deploy`: `git push origin master && git push marquee master`
* `npm run deploy:staging`: `npm install && ./node_modules/.bin/marqueestatic deploy --configuration staging`

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

Specify a [configuration](./configuration/) to use.

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


### `--use-cache`

Cache Content API responses to disk for quicker rebuilds during development.
To reset this, simply delete `.cache.json` from the project folder.


### `--verbose`

Emits detailed information about each step of the build process.
