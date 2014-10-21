
runCompilation  = require '../compiler'
startServer     = require './server'

module.exports = (project_directory) ->

    build_directory = runCompilation(project_directory)
    startServer('localhost', 5000, build_directory)

