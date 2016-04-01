# Enable support for requiring `.cjsx` files.
require('coffee-react/register')

fs                      = require 'fs-extra'
path                    = require 'path'

compileAssets           = require './compileAssets'
ContentAPI              = require './ContentAPI'
loadConfiguration       = require './loadConfiguration'
SDKError                = require './SDKError'
{ formatProjectPath }   = SDKError

getCurrentCommit        = require './getCurrentCommit'

module.exports = (project_directory, options, onCompile=null) ->

    if options.ignore_schedule
        SDKError.warn('Ignoring release schedule!')

    # Ensure build directory exists and is empty.
    build_directory = path.join(project_directory, '.dist')
    if fs.existsSync(build_directory)
        SDKError.log(SDKError.colors.grey('Clearing previous build...'))
        fs.removeSync(build_directory)

    # Provide the commit sha to the build, if available.
    getCurrentCommit project_directory, (commit_sha) ->
        _sha = if commit_sha then SDKError.colors.grey("@#{ commit_sha }") else ''
        SDKError.alwaysLog("Compiling: #{ formatProjectPath(project_directory) }#{ _sha }")

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
        project_config = loadConfiguration(project_package, options.configuration)

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


        # Set up metadata exporting function.
        metadata_for_s3 = {}

        # This is used by the metadata argument of emitFile to gather metadata
        # for each emitted file, to be added to the object’s S3 metadata.
        _exportMetadata = (file_path, file_meta) ->
            if file_meta
                try
                    JSON.stringify(file_meta)
                catch e
                    throw new SDKError('emitFile.metadata', 'emitFile metadata MUST be JSON-serializable')
                if file_path[0] is '/'
                    file_path = file_path.substring(1)
                metadata_for_s3[file_path] = file_meta

        # Save out the metadata to a `.metadata.json` file in the build
        # directory. Used by the deploy process to actually apply the metadata.
        _writeMetadata = ->
            metadata_content = JSON.stringify(metadata_for_s3)
            SDKError.log(SDKError.colors.grey("Writing #{ metadata_content.length } bytes of metadata..."))
            fs.writeFileSync(
                    path.join(build_directory, '.metadata.json')
                    metadata_content
                )

        # Set up the Content API wrapper for the project.
        api = new ContentAPI
            token               : project_config.CONTENT_API_TOKEN
            host                : project_config.CONTENT_API_HOST
            project             : project_package
            project_directory   : project_directory
            use_cache           : options.use_cache
            ignore_schedule     : options.ignore_schedule

        # Create the file handling functions for the project.
        _writeFile = require('./writeFile')(build_directory)
        _emitFile = require('./emitFile')(
            project_directory   : project_directory
            project             : project_package
            config              : project_config
            writeFile           : _writeFile
            exportMetadata      : _exportMetadata
        )
        _emitRedirect = require('./emitRedirect')(_emitFile)

        # Set a timeout for the compiler.
        TIMEOUT = 30 * 60 # 30 minutes
        _done_timeout = setTimeout ->
            throw new SDKError('compiler', "Compiler timeout. Compiler MUST call `done` within #{ TIMEOUT } seconds.")
        , TIMEOUT * 1000

        _done = ->
            SDKError.clearPrefix()
            clearTimeout(_done_timeout)
            _writeMetadata()
            # Check that the project has necessary files.
            unless _emitFile.files_emitted_indexed['404.html'] or _emitFile.files_emitted_indexed['/404.html']
                SDKError.warn('files', 'Projects SHOULD have a /404.html')
            unless _emitFile.files_emitted_indexed['index.html'] or _emitFile.files_emitted_indexed['/index.html']
                SDKError.warn('files', 'Projects SHOULD have a /index.html')

            num_indexed = Object.keys(_emitFile.files_emitted_indexed).length
            num_emitted = _emitFile.files_emitted.length
            if num_indexed isnt num_emitted
                SDKError.warn('files', "#{ num_emitted - num_indexed } too many emits. Check for multiple emits of the same file.")
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
                if project_config.ROOT_PREFIX
                    asset_dest_directory = path.join(build_directory, project_config.ROOT_PREFIX, 'assets')
                    _prefix = "/#{ project_config.ROOT_PREFIX }"
                else
                    asset_dest_directory = path.join(build_directory, 'assets')
                    _prefix = ''
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
                
                if project_config.FULLY_QUALIFY_ASSET_URL
                    _prefix = "//#{ project_config.HOST }#{ _prefix }"

                if asset_hash
                    global.ASSET_URL = "#{ _prefix }/assets/#{ asset_hash }/"
                else
                    global.ASSET_URL = "#{ _prefix }/assets/"

                _makeIncludeAssets = (asset_hash) ->
                    return (args...) ->
                        compileAssets.includeAssets
                            project_directory   : project_directory
                            build_directory     : build_directory
                            asset_hash          : asset_hash
                            assets              : args

                # Finally, invoke the compiler.
                SDKError.alwaysLog("Invoking compiler from #{ SDKError.colors.green(project_package.main) }")
                SDKError.setPrefix(SDKError.colors.grey('* compiler: '))
                try
                    buildFn
                        api             : api
                        emitFile        : _emitFile
                        emitRedirect    : _emitRedirect
                        config          : project_config
                        project         : project_package
                        payload         : options.payload
                        done            : _done
                        info            : build_info
                        includeAssets   : _makeIncludeAssets(asset_hash)
                        PRIORITY        : options.priority
                catch e
                    throw new SDKError('compiler', e)

    return build_directory
