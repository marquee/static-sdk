
# move caches to .__proof/
const fs              = require('fs-extra')
const path            = require('path')
const SDKError        = require('../compiler/SDKError')

module.exports = function clearcache (project_directory, options, which_cache=null) {
    if (null != which_cache) {
        caches_to_clear = [which_cache]
    } else {
        caches_to_clear = ['.api-cache', '.smart-cache', '.asset-cache', '.build-cache']
    }
    caches_to_clear.forEach( cache_dir => {
        const _dir = path.join(project_directory, cache_dir)
        if (fs.existsSync(_dir)) {
            SDKError.alwaysLog(`Clearing ${ cache_dir }...`)
            fs.removeSync(_dir)
            SDKError.alwaysLog(`Cleared ${ cache_dir }!`)
        } else if (cache_dir === which_cache) {
            SDKError.alwaysLog(`${ cache_dir } already empty.`)
        }
    })

}