# Enable support for requiring `.cjsx` files.
require('coffee-react/register')
# Enable support for requiring `.jsx` files.
react_preset = require('babel-preset-react')
require('babel-register')({
    ignore: /node_modules/,
    presets: [react_preset],
})



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
    getCurrentCommit project_directory, (commit_sha, is_dirty) ->
        _sha = if commit_sha then SDKError.colors.grey("@#{ commit_sha }") else ''
        SDKError.alwaysLog("Compiling: #{ formatProjectPath(project_directory) }#{ _sha }")

        # Set up or invalidate React cache if necessary
        react_cache_directory = path.join(project_directory, '.react-cache')
        if options.use_react_cache
            if is_dirty
                unless options.force
                    throw new SDKError.warn('react-cache.dirty', 'Repo has unstaged changes. Cannot use react-cache. Use --force to override.')
                SDKError.warn('react-cache.dirty', 'Repo has unstaged changes. react-cache may produce outdated results!')
            cache_commit_lock_file = path.join(react_cache_directory, '.commit.lock')
            react_cache_is_valid = false
            if fs.existsSync(react_cache_directory)
                if fs.existsSync(cache_commit_lock_file)
                    _cache_lock = fs.readFileSync(cache_commit_lock_file).toString()
                    react_cache_is_valid = commit_sha.length > 0 and _cache_lock is commit_sha
                unless react_cache_is_valid
                    SDKError.log(SDKError.colors.grey("Resetting react-cache (react-cache@#{ _cache_lock }, project@#{ commit_sha })..."))
                    fs.removeSync(react_cache_directory)
                else
                    SDKError.log(SDKError.colors.grey("react-cache@#{ _cache_lock }"))
            unless react_cache_is_valid
                fs.mkdirSync(react_cache_directory)
                fs.writeFileSync(cache_commit_lock_file, commit_sha)


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
                if project_package.marquee.configurations or project_package.proof.configurations
                    _config_notice = ' A `--configuration <name>` may be required.'
                throw new SDKError('configuration', "Project missing `package.proof.#{ prop }`.#{ _config_notice }")

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
            config              : project_config
            project_directory   : project_directory
            use_cache           : options.use_cache
            ignore_schedule     : options.ignore_schedule
            api_page_size       : options.api_page_size
            smart_cache         : options.smart_cache
            stale_after         : options.stale_after

        # Create the file handling functions for the project.
        _writeFile = require('./writeFile')(build_directory)
        _emitFile = require('./emitFile')(
            project_directory   : project_directory
            project             : project_package
            config              : project_config
            writeFile           : _writeFile
            exportMetadata      : _exportMetadata
            defer_emits         : options._defer_emits
            use_react_cache     : options.use_react_cache
            react_cache_directory: react_cache_directory
        )
        _emitRedirect = require('./emitRedirect')(_emitFile)
        _emitRSS = require('./emitRSS')(_emitFile)

        # Set a timeout for the compiler.
        TIMEOUT = 30 * 60 # 30 minutes
        _done_timeout = setTimeout ->
            throw new SDKError('compiler', "Compiler timeout. Compiler MUST call `done` within #{ TIMEOUT } seconds.")
        , TIMEOUT * 1000

        _done = ->
            SDKError.clearPrefix()
            clearTimeout(_done_timeout)

            unless options.skip_build_info
                _info_to_emit =
                    date            : build_info.date
                    commit          : build_info.commit
                    assets          : build_info.asset_hash
                    publication     : project_config.PUBLICATION_SHORT_NAME
                    env             : process.env.NODE_ENV
                    configuration   : options.configuration
                    priority        : if options.priority is Infinity then null else options.priority

                _emitFile('/_build_info/last.json', _info_to_emit)
                _emitFile("/_build_info/#{ if options.priority is Infinity then 'full' else options.priority }.json", _info_to_emit)


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
                build_info =
                    project_directory       : project_directory
                    commit                  : commit_sha
                    date                    : new Date()
                    asset_hash              : asset_hash
                    build_directory         : build_directory
                    asset_dest_directory    : asset_dest_directory
                    asset_cache_directory   : path.join(build_directory, '.asset-cache')
                global.build_info = build_info
                
                if project_config.FULLY_QUALIFY_ASSET_URL
                    _prefix = "//#{ project_config.HOST }#{ _prefix }"

                if asset_hash
                    global.ASSET_URL = "#{ _prefix }/assets/#{ asset_hash }/"
                else
                    global.ASSET_URL = "#{ _prefix }/assets/"

                
                _emitAssets = (args...) ->
                    compileAssets.includeAssets
                        project_directory   : project_directory
                        build_directory     : build_directory
                        asset_hash          : asset_hash
                        assets              : args

                # Finally, invoke the compiler.
                SDKError.alwaysLog("Invoking compiler from #{ SDKError.colors.green(project_package.main) }")
                SDKError.setPrefix(SDKError.colors.grey('* compiler: '))
                try
                    result_promise = buildFn
                        api             : api
                        emitFile        : _emitFile
                        emitRedirect    : _emitRedirect
                        emitRSS         : _emitRSS
                        emitAssets      : _emitAssets
                        config          : project_config
                        project         : project_package
                        payload         : options.payload
                        done            : _done
                        info            : build_info
                        includeAssets   : (args...) ->
                            SDKError.warn('`includeAssets` is deprecated. Used `emitAssets`.')
                            _emitAssets(args...)
                        PRIORITY        : options.priority
                    # If the buildFn correctly returns a promise, use that
                    # instead of the surrounding try/catch to guard
                    # against errors.
                    result_promise?.catch? (e) ->
                        clearTimeout(_done_timeout)
                        throw new SDKError('compiler', e)
                catch e
                    clearTimeout(_done_timeout)
                    throw new SDKError('compiler', e)

    return build_directory
