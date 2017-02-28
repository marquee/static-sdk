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

returnFile = (target_file, req, res, code=200) ->
    res.writeHead code,
        'Content-Type': mime.lookup(target_file)
    fs.createReadStream(target_file).pipe(res)



module.exports = (host, port, directory, file_set) ->

    _router = (req,res) ->
        parsed_url = url.parse(req.url)

        target_file = parsed_url.pathname
        if target_file.split('/').pop().indexOf('.') is -1
            target_file += '/index.html'

        target_file = target_file.replace(/\/\//g,'/')
        target_file_full_path = path.join(directory, target_file)

        if file_set[target_file]
            [_type, _content] = file_set[target_file].render()
            res.writeHead 200,
                'Content-Type': _type
            res.end(_content)
        else if fs.existsSync(target_file_full_path)
            util.log(SDKError.colors.green("[200] #{ req.method }: #{ req.url } ") + SDKError.colors.grey(target_file_full_path))
            returnFile(target_file_full_path, req, res)
        else
            util.log(SDKError.colors.yellow("[404] #{ req.method }: #{ req.url } ") + SDKError.colors.grey(target_file_full_path))
            not_found_file = path.join(directory, '404.html')
            if fs.existsSync(not_found_file)
                returnFile(not_found_file, req, res, 404)
            else
                notFoundHandler(req, res)

    http.createServer(_router).listen(port, host)
    server_url = "http://#{ host }:#{ port }"
    util.log("Development server running at #{ SDKError.colors.cyan.underline(server_url) }")

