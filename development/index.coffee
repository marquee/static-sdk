
runCompilation  = require '../compiler'
startServer     = require './server'
startWatcher    = require './watcher'

module.exports = (project_directory, options) ->

    build_directory = runCompilation project_directory, options, (files, assets, project_package, project_config) ->
        startServer('localhost', 5000, build_directory)
        startWatcher(project_directory, build_directory, options, project_config)
