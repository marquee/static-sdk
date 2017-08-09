// @flow

const runCompilation  = require('../compiler')
const startServer     = require('./server')
const startWatcher    = require('./watcher')
const SDKError        = require('../compiler/SDKError')
const budo            = require("budo")
const babelify        = require('babelify')
const compileAssets   = require('../compiler/compileAssets')
const current_build   = require('../CURRENT-BUILD')


const fs      = require('fs')
const mime    = require('mime')
const path    = require('path')
const url     = require('url')
const util    = require('util')

const current_error = require('../development/current_error')



function notFoundHandler (req, res) {
    res.writeHead(404)
    res.end('404 Not Found')
}

function returnFile (target_file, req, res, code=200) {
    res.writeHead(code, {
        'Content-Type': mime.lookup(target_file)
    })
    fs.createReadStream(target_file).pipe(res)
}

const _router = (directory, file_set) => (req, res, next) => {

    if (null != current_error.error) {
        console.log(current_error.error)
        res.writeHead(500, {
            'Content-Type': 'text/html'
        })
        res.end(current_error.error)
        return
    }

    const parsed_url = url.parse(req.url)

    let target_file = parsed_url.pathname
    // This is checking to see if the target_file isn't .js, .css, etc?
    if (-1 === target_file.split('/').pop().indexOf('.')) {
        target_file += '/index.html'
    }

    target_file = target_file.replace(/\/\//g,'/')

    let target_file_full_path = path.join(directory, target_file)
    if (file_set.get(target_file)) {
        const [_type, _content] = file_set.get(target_file).render()
        util.log(SDKError.colors.green(`[200] ${ req.method }: ${ req.url } `) + SDKError.colors.grey(target_file))
        res.writeHead(200, {
            'Content-Type': _type
        })
        res.end(_content)
    } else if (fs.existsSync(target_file_full_path)) {
        util.log(SDKError.colors.green(`[200] ${ req.method }: ${ req.url } `) + SDKError.colors.grey(target_file))
        returnFile(target_file_full_path, req, res)
    } else {

        // util.log(SDKError.colors.yellow(`[404] ${ req.method }: ${ req.url } `) + SDKError.colors.grey(target_file))
        const not_found_file = path.join(directory, '404.html')
        if (fs.existsSync(not_found_file)) {
            returnFile(not_found_file, req, res, 404)
        } else {
            next()
        }
    }
}




module.exports = function (project_directory, options) {
    if (options.use_react_cache) {
        throw new SDKError('react-cache.develop', '--react-cache is an invalid option for develop (it would make development impossible!)')
    }
    options._defer_emits = true
    const build_directory = runCompilation(project_directory, options, (files, assets, project_package, project_config) => {
        const host = options.host
        const port = parseInt(options.port) || 5000

        const watch_targets = fs.readdirSync(project_directory).filter( (f) => (
            ['assets', 'node_modules'].indexOf(f) === -1 && f[0] !== '.'
        )).map((path) => `./${path}` )


        const browserify_config = {
            transform: [
                babelify.configure({
                    presets: ['env', 'react'],
                    plugins : [
                          require('babel-plugin-transform-object-rest-spread')
                        , require('babel-plugin-transform-decorators-legacy').default
                        , require('babel-plugin-transform-flow-strip-types')
                    ]
                })
            ]
        }

        let is_compiling_site   = false
        let is_compiling_assets = false

        function _doAssets (file_name) {
            is_compiling_assets = true
            compileAssets({
                project_directory   : project_directory,
                build_directory     : build_directory,
                hash_files          : false,
                command_options     : options,
                project_config      : project_config,
                callback: () => {
                    // if (null != live_server) {
                    //     // The client script doesn't recognize sass files so give it some help.
                    //     live_server.refresh( file_name.replace(/\.scss$/,'.css').replace(/\.sass$/,'.css'))
                    // }
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
                    b.reload()
                    const file_counts = SDKError.colors.green(`${ files.length } files, ${ assets.length } assets`)
                    SDKError.log(`${ file_counts } generated in ${ SDKError.formatProjectPath(project_directory, build_directory) }`)
                    is_compiling_site = false
                })
            } else if (['sass', 'scss'].indexOf(ext) > -1) {
                _doAssets(file_name)
            }
        }

        function _handleChange (file_name) {
            // SDKError.log(SDKError.colors.grey(`changed: ${ file_name }`))
            // Clear cache of required project files to ensure changes are used.
            Object.keys(require.cache).forEach((key) => {
                if (key.indexOf(project_directory) > -1 && key.indexOf(path.join(project_directory, 'node_modules')) === -1) {
                    delete require.cache[key]
                }
            })
        }

        const handleFilesUpdate = (content, diffs) => {
            diffs.forEach((file_name) => {
                _handleChange(file_name)
                current_build.__reset()
                _doFiles(file_name)
            })
        }
        const b = budo(['main.jsx'], {
            live       : {
                cache : false,
                expose : true,
                include : require.resolve('./livereloadtest.js')
            },
            livePort : 37529,
            browserify : browserify_config,
            port       : port,
            host       : host,
            // cors: true,
            stream     : process.stdout,
            middleware : _router(build_directory, files._indexed),
            dir        : [project_directory, "views", "layouts", "components" ] // these need to be derived
        }).on('connect', (ev) => {
            const wss = ev.webSocketServer

            wss.on('connection', function (socket) {
              console.log('[LiveReload] Client Connected')
              socket.on('message', function (message) {
                  console.log('[LiveReload] Message from client:', JSON.parse(message))
              })
            })
        }).on('update', handleFilesUpdate)
          .on('error', (e) => {
            console.log('YO ERRORRING DUDE')
        })


        // startServer(host, port, build_directory, files._indexed)
        // startWatcher(project_directory, build_directory, options, project_config)
    })
}
