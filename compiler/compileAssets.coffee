fs              = require 'fs-extra'
sys             = require 'sys'
path            = require 'path'
crypto          = require 'crypto'

SDKError        = require './SDKError'
{ formatProjectPath } = SDKError
Sass            = require 'node-sass'
autoprefixer    = require 'autoprefixer-core'
browserify      = require 'browserify'
coffee_reactify = require 'coffee-reactify'
brfs            = require 'brfs'

walkSync        = require './walkSync'
sqwish          = require 'sqwish'
UglifyJS        = require 'uglify-js'


compileCoffee = (source_path, dest_path, project_directory, cb) ->
    SDKError.log(SDKError.colors.grey("Compiling (coffee): #{ source_path.replace(project_directory, '') }"))
    b = browserify([source_path])
    compiled = b.transform(coffee_reactify).transform(brfs).bundle (err, compiled) ->
        throw err if err
        if process.env.NODE_ENV is 'production'
            SDKError.log(SDKError.colors.grey("Minifying #{ source_path.replace(project_directory,'') }"))
            compiled = UglifyJS.minify(compiled.toString(), fromString: true).code
        fs.writeFile dest_path, compiled, (err) ->
            throw err if err
            cb()

compileSass = (source_path, dest_path, project_directory, cb) ->
    SDKError.log(SDKError.colors.grey("Compiling (sass): #{ source_path.replace(project_directory, '') }"))
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
            if process.env.NODE_ENV is 'production'
                SDKError.log(SDKError.colors.grey("Minifying #{ source_path.replace(project_directory,'') }"))
                compiled = sqwish.minify(compiled.toString())
            fs.writeFile dest_path, compiled, (err) ->
                throw err if err
                cb()

copyAndMinifyJS = (source, destination, project_directory, callback) ->
    fs.readFile source, (err, file_data) ->
        throw err if err?
        if process.env.NODE_ENV is 'production'
            SDKError.log(SDKError.colors.grey("Minifying #{ source.replace(project_directory,'') }"))
            file_data = UglifyJS.minify(file_data.toString(), fromString: true).code
        fs.writeFile destination, file_data, (err) ->
            throw err if err?
            callback()

copyAndMinifyCSS = (source, destination, project_directory, callback) ->
    fs.readFile source, (err, file_data) ->
        throw err if err?
        if process.env.NODE_ENV is 'production'
            SDKError.log(SDKError.colors.grey("Minifying #{ source.replace(project_directory,'') }"))
            file_data = sqwish.minify(file_data.toString())
        fs.writeFile destination, file_data, (err) ->
            throw err if err?
            callback()

copyAsset = (source, destination, project_directory, callback) ->
    SDKError.log(SDKError.colors.grey("Copying #{ source.replace(project_directory,'') }"))
    fs.copy source, destination, ->
        callback()


processAsset = (opts) ->
    SDKError.log("Processing asset: #{ formatProjectPath(opts.project_directory, opts.asset) }")
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
        when 'js'
            copyAndMinifyJS opts.asset, dest_path, opts.project_directory, ->
                opts.callback()
        when 'css'
            copyAndMinifyJS opts.asset, dest_path, opts.project_directory, ->
                opts.callback()
        else
            copyAsset opts.asset, dest_path, opts.project_directory, ->
                opts.callback()

copyAssetsToBuild = (project_directory, asset_cache_dir, asset_dest_dir) ->
    _to_copy = []
    _names = ['script.js', 'style.css']
    walkSync(asset_cache_dir).forEach (f) ->
        # The file is script.js, style.css, or a non-script/-style asset.
        if (f.split('.').pop() not in ['js', 'css']) or f.split('/').pop() in _names
            dest_path = f.replace(asset_cache_dir, asset_dest_dir)
            _to_copy.push(source: f, destination: dest_path)
    
    SDKError.log("Copying #{ SDKError.colors.green(_to_copy.length) } assets to build: #{ formatProjectPath(project_directory, asset_dest_dir) }")

    _to_copy.forEach (f) ->
        fs.copySync(f.source, f.destination)
        compileAssets.files_emitted.push(f.destination)


# All assets get compiled and placed into .asset-cache. This allows <Asset>
# tags in the compiler to inline certain files. However, only script.js and
# style.css (and any non-js/-css) get copied into the build output folder.
compileAssets = (opts) ->
    # Reset the count each run.
    compileAssets.files_emitted = []

    {
        project_directory
        build_directory
        callback
        hash_files
        project_config
    } = opts

    asset_source_dir    = path.join(project_directory, 'assets')
    asset_cache_dir     = path.join(build_directory, '.asset-cache')

    if project_config.ROOT_PREFIX
        asset_dest_dir = path.join(build_directory, project_config.ROOT_PREFIX, 'assets')
    else
        asset_dest_dir = path.join(build_directory, 'assets')

    # Asset folder is not strictly required, so only warn if it doesn't exist.
    unless fs.existsSync(asset_source_dir)
        SDKError.warn('assets', 'No project ./assets/ folder found.')
        callback?(null)
        return

    fs.ensureDirSync(asset_cache_dir)
    fs.ensureDirSync(asset_dest_dir)

    # Ignore _ prefixed files to prevent trying to compile imported sass files
    # on their own.
    assets = walkSync(asset_source_dir, ['_','.'])
    to_process = assets.length
    assets.forEach (asset) ->
        processAsset
            asset_source_dir    : asset_source_dir
            asset_cache_dir     : asset_cache_dir
            asset_dest_dir      : asset_dest_dir
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

                    copyAssetsToBuild(project_directory, asset_cache_dir, asset_dest_dir)
                    callback?(asset_hash)

compileAssets.files_emitted = []

# Export processAsset so it can be used directly, bypassing path definitions.
compileAssets.processAsset = processAsset

compileAssets.includeAssets = (opts) ->
    {
        project_directory
        build_directory
        assets
        asset_hash
    } = opts

    assets.forEach (f) ->
        _f = f.split('.')
        _ext = _f.pop()
        switch _ext
            when 'coffee', 'cjsx'
                _f.push('js')
            when 'sass'
                _f.push('css')
            else
                _f.push(_ext)
        _f = _f.join('.')
        _source = path.join(build_directory, '.asset-cache', _f)
        if asset_hash
            _dest = path.join(build_directory, 'assets', asset_hash, _f)
        else
            _dest = path.join(build_directory, 'assets', _f)
        unless fs.existsSync(_source)
            throw new SDKError('assets.emitAssets', "Asset specified by emitAssets not found: #{ f }")
        SDKError.log(SDKError.colors.grey("Including asset: #{ f }"))
        fs.copySync(_source, _dest)
        compileAssets.files_emitted.push(_dest)

module.exports = compileAssets