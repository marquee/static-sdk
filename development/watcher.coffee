fs              = require 'fs'
path            = require 'path'
watch           = require 'node-watch'
SDKError        = require '../compiler/SDKError'
compileAssets   = require '../compiler/compileAssets'
runCompilation  = require '../compiler'

module.exports = (project_directory, build_directory) ->
    SDKError.log("Watching for changes: #{ SDKError.formatProjectPath(project_directory) }")

    # Selectively watch to avoid EMFILE errors.
    watch_targets = fs.readdirSync(project_directory).filter (f) ->
        f not in ['assets', 'node_modules'] and f[0] isnt '.'

    _doAssets = (file_name) ->
        compileAssets
            project_directory   : project_directory
            build_directory     : build_directory
            hash_files          : false
            callback: ->
                file_counts = SDKError.colors.green("#{ compileAssets.files_emitted.length } assets")
                SDKError.log("#{ file_counts } generated in #{ SDKError.formatProjectPath(project_directory, build_directory) }")

    _doFiles = (file_name) ->
        ext = file_name.split('.').pop()
        if ext in ['cjsx', 'coffee', 'html']
            runCompilation project_directory, (files, assets) ->
                file_counts = SDKError.colors.green("#{ files.length } files, #{ assets.length } assets")
                SDKError.log("#{ file_counts } generated in #{ SDKError.formatProjectPath(project_directory, build_directory) }")
        else if ext in ['sass']
            _doAssets(file_name)

    watch path.join(project_directory, 'assets'), (file_name) ->
        SDKError.log(SDKError.colors.grey("changed: #{ file_name }"))
        _doAssets(file_name)
    watch watch_targets, (file_name) ->
        SDKError.log(SDKError.colors.grey("changed: #{ file_name }"))
        _doFiles(file_name)
