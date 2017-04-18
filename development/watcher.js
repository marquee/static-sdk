const fs              = require('fs')
const path            = require('path')
const watch           = require('node-watch')
const SDKError        = require('../compiler/SDKError')
const compileAssets   = require('../compiler/compileAssets')
const runCompilation  = require('../compiler')

module.exports = function watcher (project_directory, build_directory, options, project_config) {
    SDKError.log(`Watching for changes: ${ SDKError.formatProjectPath(project_directory) }`)

    let is_compiling_assets = false
    let is_compiling_site = false

    // Selectively watch to avoid EMFILE errors.
    const watch_targets = fs.readdirSync(project_directory).filter( (f) => {
        ['assets', 'node_modules'].indexOf(f) === -1 && f[0] !== '.'
    })

    function _doAssets (file_name) {
        is_compiling_assets = true
        compileAssets({
            project_directory   : project_directory,
            build_directory     : build_directory,
            hash_files          : false,
            command_options     : options,
            project_config      : project_config,
            callback: () => {
                const file_counts = SDKError.colors.green(`${ compileAssets.files_emitted.length } assets`)
                SDKError.log(`${ file_counts } generated in ${ SDKError.formatProjectPath(project_directory, build_directory) }`)
                is_compiling_assets = false
            },
        })
    }

    function _doFiles (file_name) {
        const ext = file_name.split('.').pop()
        if (['js', 'jsx', 'cjsx', 'coffee', 'html'].indexOf(ext)) {
            is_compiling_site = true
            runCompilation(project_directory, options, (files, assets) => {
                const file_counts = SDKError.colors.green(`${ files.length } files, ${ assets.length } assets`)
                SDKError.log(`${ file_counts } generated in ${ SDKError.formatProjectPath(project_directory, build_directory) }`)
                is_compiling_site = false
            })
        } else if (['sass', 'scss'].indexOf(ext) > -1) {
            _doAssets(file_name)
        }
    }

    function _handleChange (file_name) {
        SDKError.log(SDKError.colors.grey(`changed: ${ file_name }`))
        // Clear cache of required project files to ensure changes are used.
        Object.keys(require.cache).forEach((key) => {
            if (key.indexOf(project_directory) > -1 && key.indexOf(path.join(project_directory, 'node_modules')) === -1) {
                delete require.cache[key]
            }
        })
    }

    watch(path.join(project_directory, 'assets'), (file_name) => {
        if (!is_compiling_assets) {
            _handleChange(file_name)
            _doAssets(file_name)
        }
    })
    watch(watch_targets, (file_name) => {
        if (!is_compiling_assets && !is_compiling_site) {
            _handleChange(file_name)
            _doFiles(file_name)
        }
    })
}