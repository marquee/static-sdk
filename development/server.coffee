http    = require 'http'
fs      = require 'fs'
mime    = require 'mime'
path    = require 'path'
url     = require 'url'
util    = require 'util'

SDKError = require '../compiler/SDKError'

notFoundHandler = (req, res) ->
    res.writeHead(404)
    res.end('404 Not Found')

returnFile = (target_file, req, res) ->
    res.writeHead 200,
        'Content-Type': mime.lookup(target_file)
    fs.createReadStream(target_file).pipe(res)



module.exports = (host, port, directory) ->

    _router = (req,res) ->
        parsed_url = url.parse(req.url)

        target_file = parsed_url.pathname
        if target_file.split('/').pop().indexOf('.') is -1
            target_file += '/index.html'

        target_file = path.join(directory, target_file)
        if fs.existsSync(target_file)
            util.log(SDKError.colors.green("[200] #{ req.method }: #{ req.url } ") + SDKError.colors.grey(target_file))
            returnFile(target_file, req, res)
        else
            util.log(SDKError.colors.yellow("[404] #{ req.method }: #{ req.url } ") + SDKError.colors.grey(target_file))
            notFoundHandler(req, res)

    http.createServer(_router).listen(port, host)
    server_url = "http://#{ host }:#{ port }"
    util.log("Development server running at #{ SDKError.colors.cyan.underline(server_url) }")

