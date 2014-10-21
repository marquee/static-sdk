fs              = require 'fs-extra'
sys             = require 'sys'
path            = require 'path'
crypto          = require 'crypto'

util            = require 'util'
SDKError        = require './SDKError'
{ formatProjectPath } = SDKError
Sass            = require 'node-sass'
autoprefixer    = require 'autoprefixer-core'
browserify      = require 'browserify'
coffee_reactify = require 'coffee-reactify'

# Using a synchronous version of walk for simplicity
walkSync = (dir) ->
    results = []
    list = fs.readdirSync(dir)
    for f in list
        file = path.join(dir,f)
        stat = fs.statSync(file)
        if stat?.isDirectory()
            results.push(walkSync(file)...)
        else
            unless f[0] is '.'
                results.push(file)
    return results



compileCoffee = (source_path, dest_path, project_directory, cb) ->
    util.log(SDKError.colors.grey("Compiling (coffee): #{ source_path.replace(project_directory, '') }"))
    b = browserify([source_path])
    compiled = b.transform(coffee_reactify).bundle (err, compiled) ->
        throw err if err
        console.log 'compiled coffee'
        fs.writeFile dest_path, compiled, (err) ->
            throw err if err
            cb()

compileSass = (source_path, dest_path, project_directory, cb) ->
    util.log(SDKError.colors.grey("Compiling (sass): #{ source_path.replace(project_directory, '') }"))
    Sass.render
        file: source_path
        includePaths: [
            project_directory
            path.join(project_directory, 'node_modules', 'marquee-static-sdk', 'stylesheets')
        ]
        error: (err) ->
            throw err if err
        success: (compiled) ->
            compiled = autoprefixer.process(compiled).css
            console.log 'compiled sass'
            fs.writeFile dest_path, compiled, (err) ->
                throw err if err
                cb()



processAsset = (opts) ->
    util.log("Processing asset: #{ formatProjectPath(opts.project_directory, opts.asset) }")
    dest_path = opts.asset.replace(opts.asset_source_dir, opts.asset_cache_dir)
    path_parts = dest_path.split('.')
    switch path_parts.pop()
        when 'coffee'
            path_parts.push('js')
            dest_path = path_parts.join('.')
            compileCoffee opts.asset, dest_path, opts.project_directory, ->
                opts.callback()
        when 'sass'
            path_parts.push('css')
            dest_path = path_parts.join('.')
            compileSass opts.asset, dest_path, opts.project_directory, ->
                opts.callback()
        else
            fs.copy opts.asset, dest_path, ->
                opts.callback()

copyAssetsToBuild = (asset_cache_dir, asset_dest_dir, callback) ->
    util.log("Copying assets to build: #{ formatProjectPath(asset_dest_dir) }")
    # TODO: allow this to be modified by the project (includeAssets('base.coffee'))
    _names = ['script.js', 'style.css']
    walkSync(asset_cache_dir).forEach (f) ->
        # The file is script.js, style.css, or a non-script/-style asset.
        if not f.split('.').pop() in ['js', 'css'] or f.split('/').pop() in _names
            dest_path = f.replace(asset_cache_dir, asset_dest_dir)
            fs.copySync(f, dest_path)



compileAssets = (opts) ->

    {
        project_directory
        build_directory
        callback
        hash_files
    } = opts

    asset_source_dir    = path.join(project_directory, 'assets')
    asset_cache_dir     = path.join(build_directory, '.asset-cache')
    asset_dest_dir      = path.join(build_directory, 'assets')

    # Asset folder is not strictly required, so only warn if it doesn't exist.
    unless fs.existsSync(asset_source_dir)
        SDKError.warn('assets', 'No project ./assets/ folder found.')
        callback(null)
        return

    fs.ensureDirSync(asset_cache_dir)
    fs.ensureDirSync(asset_dest_dir)

    assets = walkSync(asset_source_dir)
    to_process = assets.length
    assets.forEach (asset) ->
        processAsset
            asset_source_dir    : asset_source_dir
            asset_cache_dir     : asset_cache_dir
            asset               : asset
            project_directory   : project_directory
            callback: ->
                to_process -= 1
                if to_process is 0
                    asset_hash = null
                    if hash_files
                        # Hash all the compiled assets, not just the auto ones.
                        compiled_assets = walkSync(asset_cache_dir)
                        hash = crypto.createHash('md5')
                        compiled_assets.sort()
                        compiled_assets.forEach (asset_path) ->
                            _source_content = fs.readFileSync(asset_path)
                            hash.update(_source_content, 'binary')
                        asset_hash = hash.digest('hex')
                        asset_dest_dir = path.join(asset_dest_dir, asset_hash)

                    copyAssetsToBuild(asset_cache_dir, asset_dest_dir)
                    callback(asset_hash)

# compileAssets.includeAssets = (opts) ->
#     {
#         project_directory
#         build_directory
#         assets
#         asset_hash
#     } = opts
#     # if asset is directory, process contents
#     # console.log asset_hash, assets

module.exports = compileAssets