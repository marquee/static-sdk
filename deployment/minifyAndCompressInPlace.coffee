
zlib        = require 'zlib'
UglifyJS    = require 'uglify-js'
sqwish      = require 'sqwish'
fs          = require 'fs'
minifyCSS = (source) ->
    return sqwish.minify(source)

minifyJS = (source) ->
    return UglifyJS.minify(source, fromString: true).code

gzipCompress = (source, cb) ->
    zlib.gzip source, (err, result) ->
        throw err if err?
        cb(result)

COMPRESSABLE = ['js', 'css', 'svg', 'html', 'txt', 'json', 'xml']

module.exports = (local_files, callback) ->
    to_process = local_files.length

    local_files.forEach (f) ->
        _ext = f.split('.').pop()
        file_content = fs.readFileSync(f)
        if _ext is 'js'
            file_content = minifyJS(file_content.toString())
        else if _ext is 'css'
            file_content = minifyCSS(file_content.toString())
        _finishFile = ->
            fs.writeFileSync(f, file_content)
            to_process -= 1
            if to_process is 0
                callback()

        if _ext in COMPRESSABLE
            gzipCompress file_content, (compressed) ->
                file_content = compressed
                _finishFile()
        else
            _finishFile()