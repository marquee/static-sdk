# Enable support for requiring `.cjsx` files.
require('coffee-react/register')

fs                  = require 'fs-extra'
path                = require 'path'
util                = require 'util'

ContentAPI          = require './ContentAPI'
formatProjectPath   = require './formatProjectPath'
SDKError            = require './SDKError'

{ exec } = require 'child_process'

_getCurrentCommit = (directory, cb) ->
    unless fs.existsSync(path.join(directory, '.git'))
        cb(null)
    exec 'git rev-parse --short=N HEAD', cwd: directory, (err, stdout, stderr) ->
        cb(stdout.split('\n').join('')) 


module.exports = (project_directory, onCompile=null) ->
    # Ensure build directory exists and is empty.
    build_directory = path.join(project_directory, '.build')
    if fs.existsSync(build_directory)
        util.log(SDKError.colors.grey('Clearing previous build...'))
        fs.removeSync(build_directory)

    # Provide the commit sha to the build, if available.
    _getCurrentCommit project_directory, (commit_sha) ->
        _sha = if commit_sha then SDKError.colors.grey(" (@ #{ commit_sha })") else ''
        util.log("Compiling: #{ formatProjectPath(project_directory) }#{ _sha }")

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

        # Create the file handling functions for the project.
        _writeFile = require('./writeFile')(build_directory)
        _emitFile = require('./emitFile')(
            project_directory   : project_directory
            project             : project_package
            config              : project_config
            writeFile           : _writeFile
        )

        # Set a timeout for the compiler. Must complete within 60 seconds.
        _done_timeout = setTimeout ->
            throw new SDKError('compiler', 'Compiler timeout. Compiler MUST call `done` within 60 seconds.')
        , 60 * 1000
        _done = ->
            clearTimeout(_done_timeout)
            # Check that the project has necessary files.
            unless '404.html' in _emitFile.files_emitted
                SDKError.warn('files', 'Projects SHOULD have a /404.html')
            unless 'index.html' in _emitFile.files_emitted
                SDKError.warn('files', 'Projects SHOULD have a /index.html')
            onCompile?(_emitFile.files_emitted)

        # TODO: compile assets
        asset_hash = null

        # Make the config globally available. Yes, globals are Bad(tm), but this
        # makes for a substantially simpler compiler.
        global.config = project_config

        # Finally, invoke the compiler.
        try
            buildFn
                api         : api
                emitFile    : _emitFile
                config      : project_config
                project     : project_package
                done        : _done
                info:
                    commit      : commit_sha
                    date        : new Date()
                    asset_hash  : asset_hash
                
        catch e
            throw new SDKError('compiler', e)

    return build_directory
        # make temp directory for asset cache
        # build all assets to asset cache
        # make a temp directory for project
        # copy auto assets
        # build project into temp directory
