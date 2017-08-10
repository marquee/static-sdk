// @flow

const http    = require('http')
const fs      = require('fs')
const mime    = require('mime')
const path    = require('path')
const url     = require('url')
const util    = require('util')

const SDKError = require('../compiler/SDKError')

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

const current_error = require('../development/current_error')


module.exports = function (host, port, directory, file_set) {
    // console.log('file_set', file_set)
    function _router (req,res) {

        if (null != current_error.error) {
            res.writeHead(500, {
                'Content-Type': 'text/html'
            })
            res.end(current_error.error)
            return
        }

        const parsed_url = url.parse(req.url)

        let target_file = parsed_url.pathname
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
            util.log(SDKError.colors.yellow(`[404] ${ req.method }: ${ req.url } `) + SDKError.colors.grey(target_file))
            const not_found_file = path.join(directory, '404.html')
            if (fs.existsSync(not_found_file)) {
                returnFile(not_found_file, req, res, 404)
            } else {
                notFoundHandler(req, res)
            }
        }
    }

    http.createServer(_router).listen(port, host)
    const server_url = `http://${ host }:${ port }`
    util.log(`Development server running at ${ SDKError.colors.cyan.underline(server_url) }`)
}
