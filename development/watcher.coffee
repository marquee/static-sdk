fs              = require 'fs'
path            = require 'path'
watch           = require 'node-watch'
SDKError        = require '../compiler/SDKError'
compileAssets   = require '../compiler/compileAssets'
runCompilation  = require '../compiler'

module.exports = (project_directory, build_directory, options, project_config) ->
    SDKError.log("Watching for changes: #{ SDKError.formatProjectPath(project_directory) }")

    is_compiling_assets = false
    is_compiling_site = false

    # Selectively watch to avoid EMFILE errors.
    watch_targets = fs.readdirSync(project_directory).filter (f) ->
        f not in ['assets', 'node_modules'] and f[0] isnt '.'

    _doAssets = (file_name) ->
        is_compiling_assets = true
        compileAssets
            project_directory   : project_directory
            build_directory     : build_directory
            hash_files          : false
            command_options     : options
            project_config      : project_config
            callback: ->
                file_counts = SDKError.colors.green("#{ compileAssets.files_emitted.length } assets")
                SDKError.log("#{ file_counts } generated in #{ SDKError.formatProjectPath(project_directory, build_directory) }")
                is_compiling_assets = false

    _doFiles = (file_name) ->
        ext = file_name.split('.').pop()
        if ext in ['cjsx', 'coffee', 'html']
            is_compiling_site = true
            runCompilation project_directory, options, (files, assets) ->
                file_counts = SDKError.colors.green("#{ files.length } files, #{ assets.length } assets")
                SDKError.log("#{ file_counts } generated in #{ SDKError.formatProjectPath(project_directory, build_directory) }")
                is_compiling_site = false
        else if ext in ['sass']
            _doAssets(file_name)

    _handleChange = (file_name) ->
        SDKError.log(SDKError.colors.grey("changed: #{ file_name }"))
        # Clear cache of required project files to ensure changes are used.
        Object.keys(require.cache).forEach (key) ->
            if key.indexOf(project_directory) > -1 and key.indexOf(path.join(project_directory, 'node_modules')) is -1
                delete require.cache[key]

    watch path.join(project_directory, 'assets'), (file_name) ->
        unless is_compiling_assets
            _handleChange(file_name)
            _doAssets(file_name)
    watch watch_targets, (file_name) ->
        unless is_compiling_assets or is_compiling_site
            _handleChange(file_name)
            _doFiles(file_name)
