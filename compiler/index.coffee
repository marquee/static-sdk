# Enable support for requiring `.cjsx` files.
require('coffee-react/register')

fs                      = require 'fs-extra'
path                    = require 'path'

compileAssets           = require './compileAssets'
ContentAPI              = require './ContentAPI'
SDKError                = require './SDKError'
{ formatProjectPath }   = SDKError

getCurrentCommit        = require './getCurrentCommit'

module.exports = (project_directory, options, onCompile=null) ->
    # Ensure build directory exists and is empty.
    build_directory = path.join(project_directory, '.dist')
    if fs.existsSync(build_directory)
        SDKError.log(SDKError.colors.grey('Clearing previous build...'))
        fs.removeSync(build_directory)

    # Provide the commit sha to the build, if available.
    getCurrentCommit project_directory, (commit_sha) ->
        _sha = if commit_sha then SDKError.colors.grey("@#{ commit_sha }") else ''
        SDKError.log("Compiling: #{ formatProjectPath(project_directory) }#{ _sha }")

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
        SDKError.log("Project entrypoint: #{ formatProjectPath(project_directory, project_main) }")

        # Load and validate the Marquee-specific compiler configuration.
        project_config = {}

        unless project_package.marquee
            throw new SDKError('configuration', "Project missing `package.marquee`.")

        for k,v of project_package.marquee
            unless k is 'configurations'
                project_config[k] = v

        # Override config with specified configuration values.
        if options.configuration
            unless project_package.marquee.configurations[options.configuration]
                _available_configs = Object.keys(project_package.marquee.configurations).map (c) -> "`#{ c }`"
                _available_configs = _available_configs.join(', ')
                throw new SDKError('configuration', "Unknown configuration specified: `#{ options.configuration }`. Package has #{ _available_configs }.")
            for k,v of project_package.marquee.configurations[options.configuration]
                project_config[k] = v

        ['CONTENT_API_TOKEN', 'CONTENT_API_HOST', 'HOST'].forEach (prop) ->
            unless project_config[prop]
                _config_notice = ''
                if project_package.marquee.configurations
                    _config_notice = ' A `--configuration <name>` may be required.'
                throw new SDKError('configuration', "Project missing `package.marquee.#{ prop }`.#{ _config_notice }")

        # Load the project compiler entrypoint.
        buildFn = require(project_main)
        unless typeof buildFn is 'function'
            throw new SDKError('entrypoint', "Project main MUST export a function. Got #{ SDKError.colors.underline(typeof buildFn) }.")

        # Set up the Content API wrapper for the project.
        api = new ContentAPI
            token               : project_config.CONTENT_API_TOKEN
            host                : project_config.CONTENT_API_HOST
            project             : project_package
            project_directory   : project_directory
            use_cache           : options.use_cache

        # Create the file handling functions for the project.
        _writeFile = require('./writeFile')(build_directory)
        _emitFile = require('./emitFile')(
            project_directory   : project_directory
            project             : project_package
            config              : project_config
            writeFile           : _writeFile
        )

        # Set a timeout for the compiler.
        TIMEOUT = 30 * 60 # 30 minutes
        _done_timeout = setTimeout ->
            throw new SDKError('compiler', "Compiler timeout. Compiler MUST call `done` within #{ TIMEOUT } seconds.")
        , TIMEOUT * 1000

        _done = ->
            SDKError.clearPrefix()
            clearTimeout(_done_timeout)
            # Check that the project has necessary files.
            unless '404.html' in _emitFile.files_emitted
                SDKError.warn('files', 'Projects SHOULD have a /404.html')
            unless 'index.html' in _emitFile.files_emitted
                SDKError.warn('files', 'Projects SHOULD have a /index.html')
            onCompile?(_emitFile.files_emitted, compileAssets.files_emitted, project_package, project_config)

        compileAssets
            project_directory   : project_directory
            build_directory     : build_directory
            hash_files          : process.env.NODE_ENV is 'production'
            project_config      : project_config
            callback: (asset_hash) ->
                # Make the config globally available. Yes, globals are Bad(tm), but this
                # makes for a substantially simpler compiler.
                global.config = project_config
                asset_dest_directory = path.join(build_directory, 'assets')
                if asset_hash
                    asset_dest_directory = path.join(asset_dest_directory, asset_hash)
                global.build_info =
                    project_directory       : project_directory
                    commit                  : commit_sha
                    date                    : new Date()
                    asset_hash              : asset_hash
                    build_directory         : build_directory
                    asset_dest_directory    : asset_dest_directory
                    asset_cache_directory   : path.join(build_directory, '.asset-cache')
                if asset_hash
                    global.ASSET_URL = "/assets/#{ asset_hash }/"
                else
                    global.ASSET_URL = '/assets/'

                _makeIncludeAssets = (asset_hash) ->
                    return (args...) ->
                        compileAssets.includeAssets
                            project_directory   : project_directory
                            build_directory     : build_directory
                            asset_hash          : asset_hash
                            assets              : args

                # Finally, invoke the compiler.
                SDKError.log("Invoking compiler from #{ SDKError.colors.green(project_package.main) }")
                SDKError.setPrefix(SDKError.colors.grey('* compiler: '))
                try
                    buildFn
                        api             : api
                        emitFile        : _emitFile
                        config          : project_config
                        project         : project_package
                        payload         : options.payload
                        done            : _done
                        info            : build_info
                        includeAssets   : _makeIncludeAssets(asset_hash)
                catch e
                    throw new SDKError('compiler', e)

    return build_directory
