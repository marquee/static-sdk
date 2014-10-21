
runCompilation  = require '../compiler'
startServer     = require './server'
startWatcher    = require './watcher'

module.exports = (project_directory) ->

    build_directory = runCompilation project_directory, (files) ->
        startServer('localhost', 5000, build_directory)
        startWatcher(project_directory, build_directory)
