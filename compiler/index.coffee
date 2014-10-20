# Enable support for requiring `.cjsx` files.
require('coffee-react/register')

fs      = require 'fs'
path    = require 'path'
util    = require 'util'

ContentAPI          = require './ContentAPI'
formatProjectPath   = require './formatProjectPath'
SDKError            = require './SDKError'

module.exports = (project_directory) ->

    util.log("Compiling: #{ formatProjectPath(project_directory) }")


    # Load the project's package.json file, if present and valid.
    project_package_file = path.join(project_directory, 'package.json')
    unless fs.existsSync(project_package_file)
        throw new SDKError('package', 'Unable to find package.json')
    project_package_content = fs.readFileSync(project_package_file).toString()
    try
        project_package = JSON.parse(project_package_content)
    catch e
        throw new SDKError('package', 'Unable to parse package.json. Is it valid JSON?')

    # Identify the project entrypoint.
    unless project_package.main
        throw new SDKError('configuration', "Project missing `package.main` (typically \"./main.coffee\")")
    project_main = path.join(project_directory, project_package.main)
    util.log("Project entrypoint: #{ formatProjectPath(project_directory, project_main) }")

    # Load and validate the Marquee-specific compiler configuration.
    project_config = project_package.marquee
    unless project_config
        throw new SDKError('configuration', "Project missing `package.marquee`.")
    ['CONTENT_API_TOKEN', 'CONTENT_API_ROOT', 'HOST'].forEach (prop) ->
        unless project_config[prop]
            throw new SDKError('configuration', "Project missing `package.marquee.#{ prop }`.")

    # Load the project compiler entrypoint.
    buildFn = require(project_main)
    unless typeof buildFn is 'function'
        throw new SDKError('entrypoint', "Project main MUST export a function. Got #{ SDKError.colors.underline(typeof buildFn) }.")

    # Set up the Content API wrapper for the project.
    api = new ContentAPI
        token   : project_config.CONTENT_API_TOKEN
        root    : project_config.CONTENT_API_ROOT
        cache   : false
        project : project_package

    # Make the config globally available. Yes, globals are Bad(tm), but this
    # makes for a substantially simpler compiler.
    global.config = project_config

    # Create the emitFile function for the project.
    emitFile = require('./emitFile')(project_directory, project_package, project_config)

    # Finally, invoke the compiler.
    try
        buildFn
            api         : api
            emitFile    : emitFile
            config      : project_config
            project     : project_package
    catch e
        throw new SDKError('compiler', e)

    # make temp directory for asset cache
    # build all assets to asset cache
    # make a temp directory for project
    # copy auto assets
    # build project into temp directory
