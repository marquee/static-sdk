// @flow

const autoprefixer    = require('autoprefixer')
const babelify        = require('babelify')
const brfs            = require('brfs')
const browserify      = require('browserify')
const coffee_reactify = require('coffee-reactify')
const crypto          = require('crypto')
const envify          = require('envify/custom')
const fs              = require('fs-extra')
const path            = require('path')
const postcss         = require('postcss')
const Sass            = require('node-sass')
const SDKError        = require('./SDKError')
const sqwish          = require('sqwish')
const sys             = require('sys')
const UglifyJS        = require('uglify-es')
const walkSync        = require('./walkSync')
const { formatProjectPath } = SDKError

const ERROR_STYLES = 'display: block; font-family: monospace; border-bottom: 3px solid red; padding: 24px; background-color: white; white-space: pre;'

function compileCoffee (source_path, dest_path, project_directory, cb) {
    SDKError.log(SDKError.colors.grey(`Compiling (coffee): ${ source_path.replace(project_directory, '') }`))
    const b = browserify([source_path])
    const compiled = b.transform(
        coffee_reactify
    ).transform(
        envify({ NODE_ENV: process.env.NODE_ENV })
    ).transform(brfs).bundle( (err, compiled) => {
        let compilation_error = null
        if (err) {
            console.error(err)
            compilation_error = err
            // console.error(err)
            compilation_error.formatted = `CoffeeScript compilation error:
file: ${ err.filename }

${ err.toString() }`
            compiled = `document.body.innerHTML = '<style>body { ${ ERROR_STYLES } }</style><p>' + decodeURIComponent("${ encodeURIComponent(compilation_error.formatted) }") + '</p>'`
        }
        if ('production' === process.env.NODE_ENV) {
            SDKError.log(SDKError.colors.grey(`Minifying ${ source_path.replace(project_directory,'') }`))
            compiled = UglifyJS.minify(compiled.toString()).code
        }
        fs.writeFile(dest_path, compiled, (err) => {
            if (err) {
                throw err
            }
            cb(compilation_error)
        })
    })
}

function compileSass (source_path, dest_path, project_directory, cb) {
    SDKError.log(SDKError.colors.grey(`Compiling (sass): ${ source_path.replace(project_directory, '') }`))
    Sass.render({
        file: source_path,
        includePaths: [
            project_directory,
            path.join(project_directory, 'node_modules', 'proof-sdk', 'stylesheets'),
            path.join(project_directory, 'node_modules', 'proof-contrib', 'stylesheets'),
        ],
    } , (err, compiled) => {
            let output
            let compilation_error = null
            if (err) {
                compilation_error = err
                let _err_message = err.toString()
                _err_message += '\\A    file: ' + err.file.replace(project_directory, '')
                _err_message += '\\A    line: ' + err.line.toString() + ', column: ' + err.column.toString()
                output = `body::before{ content: '${ _err_message }'; ${ ERROR_STYLES }}`
            } else {
                output = compiled.css
            }
            const _prefixing = postcss([autoprefixer]).process(output)
            _prefixing.then( (result) => {
                compiled = result.css
                if ('production' === process.env.NODE_ENV) {
                    SDKError.log(SDKError.colors.grey(`Minifying ${ source_path.replace(project_directory,'') }`))
                    compiled = sqwish.minify(compiled.toString())
                }
                fs.writeFile(dest_path, compiled, (err) => {
                    if (err) {
                        throw err
                    }
                    cb(compilation_error)
                })
            }).catch( (err) => {
                if (err) {
                    throw err
                }
            })
    })
}

function compileJS (source_path, dest_path, project_directory, cb) {
    SDKError.log(SDKError.colors.grey(`Compiling (js/x): ${ source_path.replace(project_directory, '') }`))
    const b = browserify([source_path], { extensions: ['.js', '.jsx', '.es', '.es6']})
    const compiled = b.transform(
        babelify,
        {
            presets: [
                // Require these directly so they can be properly
                // discovered by babel.
                require('babel-preset-flow'),
                require('babel-preset-react'),
                require('babel-preset-env'),
            ],
            plugins : [
                  require('babel-plugin-transform-object-rest-spread')
                , require('babel-plugin-transform-decorators-legacy').default
                , require('babel-plugin-transform-flow-strip-types')
            ]
        }
    ).transform(
        { global: true },
        envify({ NODE_ENV: process.env.NODE_ENV })
    ).transform(brfs).bundle( (err, compiled) => {
        let compilation_error = null
        if (err) {
            console.error(err)
            compilation_error = err
            // console.error(err)
            compilation_error.formatted = `JS compilation error:
file: ${ err.filename ? err.filename : '?' }
line: ${ err.loc ? err.loc.line : '?' }, column: ${ err.loc ? err.loc.column : '?' }

${ err.toString() }`
            compiled = `document.body.innerHTML = '<style>body { ${ ERROR_STYLES } }</style><p>' + decodeURIComponent("${ encodeURIComponent(compilation_error.formatted) }") + '</p>'`
        }
        let file_data = compiled.toString()

        if ('production' === process.env.NODE_ENV && null == compilation_error) {
            SDKError.log(SDKError.colors.grey(`Minifying ${ source_path.replace(project_directory,'') }`))
            file_data = UglifyJS.minify(file_data)
            if (null != file_data.error) {
                console.error(err)
                err = file_data.error
                compilation_error = file_data.error
                compilation_error.formatted = `JS compilation error:
file: ${ err.filename ? err.filename : '?' }
line: ${ err.loc ? err.loc.line : '?' }, column: ${ err.loc ? err.loc.column : '?' }

${ err.toString() }`
                file_data = `document.body.innerHTML = '<style>body { ${ ERROR_STYLES } }</style><p>' + decodeURIComponent("${ encodeURIComponent(compilation_error.formatted) }") + '</p>'`
            } else {
                file_data = file_data.code
            }
        }
        fs.writeFile(dest_path, file_data, (_err) => {
            if (_err) {
                throw _err
            }
            cb(compilation_error)
        })
    })
}

function copyAndMinifyJS (source, destination, project_directory, callback) {
    fs.readFile(source, (err, file_data) => {
        if (err) {
            throw err
        }
        if ('production' === process.env.NODE_ENV) {
            SDKError.log(SDKError.colors.grey(`Minifying ${ source.replace(project_directory,'') }`))
            file_data = UglifyJS.minify(file_data.toString()).code
        }
        fs.writeFile(destination, file_data, (err) => {
            if (err) {
                throw err
            }
            callback()
        })
    })
}

function copyAndMinifyCSS (source, destination, project_directory, callback) {
    fs.readFile(source, (err, file_data) => {
        if (err) {
            throw err
        }
        if ('production' === process.env.NODE_ENV) {
            SDKError.log(SDKError.colors.grey(`Minifying ${ source.replace(project_directory,'') }`))
            file_data = sqwish.minify(file_data.toString())
        }
        fs.writeFile(destination, file_data, (err) => {
            if (err) {
                throw err
            }
            callback()
        })
    })
}

function copyAsset (source, destination, project_directory, callback) {
    SDKError.log(SDKError.colors.grey(`Copying ${ source.replace(project_directory,'') }`))
    fs.copy(source, destination, () => {
        callback()
    })
}


function processAsset (opts) {
    SDKError.log(`Processing asset: ${ formatProjectPath(opts.project_directory, opts.asset) }`)
    let dest_path = opts.asset.replace(opts.asset_source_dir, opts.asset_cache_dir)
    const path_parts = dest_path.split('.')
    switch (path_parts.pop()) {
        case 'coffee':
            path_parts.push('js')
            dest_path = path_parts.join('.')
            compileCoffee(opts.asset, dest_path, opts.project_directory, (err) => {
                opts.callback(err)
            })
            break
        case 'sass':
        case 'scss':
            path_parts.push('css')
            dest_path = path_parts.join('.')
            compileSass(opts.asset, dest_path, opts.project_directory, (err) => {
                opts.callback(err)
            })
            break
        case 'jsx':
            path_parts.push('js')
            dest_path = path_parts.join('.')
            compileJS(opts.asset, dest_path, opts.project_directory, (err) => {
                opts.callback(err)
            })
            break
        case 'js':
            compileJS(opts.asset, dest_path, opts.project_directory, (err) => {
                opts.callback(err)
            })
            break
        case 'css':
            copyAndMinifyCSS(opts.asset, dest_path, opts.project_directory, () => {
                opts.callback()
            })
            break
        default:
            copyAsset(opts.asset, dest_path, opts.project_directory, () => {
                opts.callback()
            })
    }
}

function copyAssetsToBuild (project_directory, asset_cache_dir, asset_dest_dir) {
    const _to_copy = []
    const _names = ['script.js', 'style.css']
    walkSync(asset_cache_dir).forEach( (f) => {
        // The file is script.js, style.css, or a non-script/-style asset.
        if (['js', 'css'].indexOf(f.split('.').pop()) === -1 || _names.indexOf(f.split('/').pop()) > -1) {
            const dest_path = f.replace(asset_cache_dir, asset_dest_dir)
            _to_copy.push({ source: f, destination: dest_path })
        }
    })

    SDKError.log(`Copying ${ SDKError.colors.green(_to_copy.length) } assets to build: ${ formatProjectPath(project_directory, asset_dest_dir) }`)

    _to_copy.forEach( (f) => {
        fs.copySync(f.source, f.destination)
        compileAssets.files_emitted.push(f.destination)
    })
}


// All assets get compiled and placed into .asset-cache. This allows <Asset>
// tags in the compiler to inline certain files. However, only script.js and
// style.css (and any non-js/-css) get copied into the build output folder.
function compileAssets (opts) {
    // Reset the count each run.
    compileAssets.files_emitted = []

    const {
        project_directory,
        build_directory,
        callback,
        hash_files,
        project_config,
        build_cache,
    } = opts

    const { allow_asset_errors } = opts.command_options

    if (build_cache && build_cache.get('assets/*')) {
        callback(build_cache.get('assets/*'))
        return
    }

    const asset_source_dir    = path.join(project_directory, 'assets')
    const asset_cache_dir     = path.join(project_directory, '.asset-cache')
    let asset_dest_dir;
    if (project_config.ROOT_PREFIX) {
        asset_dest_dir = path.join(build_directory, project_config.ROOT_PREFIX, 'assets')
    } else {
        asset_dest_dir = path.join(build_directory, 'assets')
    }

    // Asset folder is not strictly required, so only warn if it doesn't exist.
    if (!fs.existsSync(asset_source_dir)) {
        SDKError.warn('assets', 'No project ./assets/ folder found.')
        callback && callback(null)
        return
    }

    let asset_hash = null
    if (hash_files) {
        // Hash all the compiled assets, not just the auto ones.
        const compiled_assets = walkSync(asset_source_dir)
        const hash = crypto.createHash('md5')
        compiled_assets.sort()
        compiled_assets.forEach( (asset_path) => {
            const _source_content = fs.readFileSync(asset_path)
            hash.update(_source_content, 'binary')
        })
        asset_hash = hash.digest('hex')
        asset_dest_dir = path.join(asset_dest_dir, asset_hash)
    }

    build_cache && build_cache.set('assets/*', asset_hash)

    fs.ensureDirSync(asset_cache_dir)
    fs.ensureDirSync(asset_dest_dir)

    // Ignore _ prefixed files to prevent trying to compile imported sass files
    // on their own.
    const assets = walkSync(asset_source_dir, ['_','.'])
    let to_process = assets.length

    assets.forEach((asset) => {
        processAsset({
            asset_source_dir    : asset_source_dir,
            asset_cache_dir     : asset_cache_dir,
            asset_dest_dir      : asset_dest_dir,
            asset               : asset,
            project_directory   : project_directory,
            callback: (compilation_error) => {
                if (null != compilation_error) {
                    console.log('\n')
                    console.error(compilation_error.formatted || compilation_error)
                    console.log('\n')
                    if (!allow_asset_errors) {
                        process.exit(1)
                    }
                }
                to_process -= 1
                if (0 === to_process) {
                    copyAssetsToBuild(project_directory, asset_cache_dir, asset_dest_dir)
                    callback && callback(asset_hash)
                }
            },
        })
    })
}

compileAssets.files_emitted = []

// Export processAsset so it can be used directly, bypassing path definitions.
compileAssets.processAsset = processAsset

compileAssets.includeAssets = (opts) => {
    const {
        project_directory,
        build_directory,
        assets,
        asset_hash,
    } = opts

    assets.forEach( (f) => {
        let _f = f.split('.')
        const _ext = _f.pop()
        switch (_ext) {
            case 'coffee':
            case 'cjsx':
            case 'jsx':
                _f.push('js')
                break
            case 'sass':
            case 'scss':
                _f.push('css')
                break
            default:
                _f.push(_ext)
        }
        _f = _f.join('.')
        const _source = path.join(project_directory, '.asset-cache', _f)
        let _dest
        if (asset_hash) {
            _dest = path.join(build_directory, 'assets', asset_hash, _f)
        } else {
            _dest = path.join(build_directory, 'assets', _f)
        }
        if (!fs.existsSync(_source)) {
            throw new SDKError('assets.emitAssets', `Asset specified by emitAssets not found: ${ f }`)
        }
        SDKError.log(SDKError.colors.grey(`Including asset: ${ f }`))
        fs.copySync(_source, _dest)
        compileAssets.files_emitted.push(_dest)
    })
}
module.exports = compileAssets
