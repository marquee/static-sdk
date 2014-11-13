
runCompilation  = require '../compiler'
SDKError        = require '../compiler/SDKError'
module.exports = (project_directory, options) ->
    build_directory = runCompilation project_directory, options, (files, assets) ->
        file_counts = SDKError.colors.green("#{ files.length } files, #{ assets.length } assets")
        SDKError.log("#{ file_counts } generated in #{ SDKError.formatProjectPath(project_directory, build_directory) }")

