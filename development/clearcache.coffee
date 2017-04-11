# move caches to .__proof/
fs              = require 'fs-extra'
path            = require 'path'
SDKError        = require '../compiler/SDKError'
module.exports = (project_directory, options, which_cache=null) ->
    if which_cache
        caches_to_clear = [which_cache]
    else
        caches_to_clear = ['.api-cache', '.smart-cache', '.asset-cache', '.build-cache']
    caches_to_clear.forEach (cache_dir) ->
        _dir = path.join(project_directory, cache_dir)
        if fs.existsSync(_dir)
            SDKError.alwaysLog("Clearing #{ cache_dir }...")
            fs.removeSync(_dir)
            SDKError.alwaysLog("Cleared #{ cache_dir }!")
        else if cache_dir is which_cache
            SDKError.alwaysLog("#{ cache_dir } already empty.")

