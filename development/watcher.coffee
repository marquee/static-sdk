watch = require 'node-watch'
SDKError = require '../compiler/SDKError'
compileAssets = require '../compiler/compileAssets'
runCompilation = require '../compiler'

path = require 'path'
module.exports = (project_directory, build_directory) ->
    SDKError.log("Watching for changes: #{ SDKError.formatProjectPath(project_directory) }")
    watch project_directory, (file_name) ->
        in_dot_dir = file_name.split('/').some (f) -> f[0] is '.'
        if in_dot_dir
            return
        SDKError.log(SDKError.colors.grey("changed: #{ file_name }"))
        ext = file_name.split('.').pop()
        if file_name.indexOf("#{ path.join(project_directory, 'assets') }") is 0 or ext is 'sass'
            compileAssets
                project_directory   : project_directory
                build_directory     : build_directory
                hash_files          : false
                callback: ->
                    file_counts = SDKError.colors.green("#{ compileAssets.files_emitted.length } assets")
                    SDKError.log("#{ file_counts } generated in #{ SDKError.formatProjectPath(project_directory, build_directory) }")
        else
            if ext in ['cjsx', 'coffee', 'html']
                runCompilation project_directory, (files, assets) ->
                    file_counts = SDKError.colors.green("#{ files.length } files, #{ assets.length } assets")
                    SDKError.log("#{ file_counts } generated in #{ SDKError.formatProjectPath(project_directory, build_directory) }")

