
const runCompilation    = require('../compiler')
const SDKError          = require('../compiler/SDKError')
module.exports = function build (project_directory, options) {
    const build_directory = runCompilation(project_directory, options, (files, assets) => {
        file_counts = SDKError.colors.green(`${ files.length } files, ${ assets.length } assets`)
        SDKError.log(`${ file_counts } generated in ${ SDKError.formatProjectPath(project_directory, build_directory) }`)
    })
}
