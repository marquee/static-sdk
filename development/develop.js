// @flow
const runCompilation  = require('../compiler')
const startServer     = require('./server')
const startWatcher    = require('./watcher')
const SDKError        = require('../compiler/SDKError')

module.exports = function (project_directory , options) {
    if (options.use_react_cache) {
        throw new SDKError('react-cache.develop', '--react-cache is an invalid option for develop (it would make development impossible!)')
    }
    options._defer_emits = true
    const build_directory = runCompilation(project_directory, options, (files, assets, project_package, project_config) => {
        const host = options.host
        const port = parseInt(options.port) || 5000
        startServer(host, port, build_directory, files._indexed)
        startWatcher(project_directory, build_directory, options, project_config)
    })
}
