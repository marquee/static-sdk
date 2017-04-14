
zlib        = require 'zlib'
fs          = require 'fs'
SDKError    = require '../compiler/SDKError'


COMPRESSABLE = ['js', 'css', 'svg', 'html', 'txt', 'json', 'xml']

processFile = (f) ->
    new Promise (resolve, reject) ->
        zlib.gzip fs.readFileSync(f), (err, result) ->
            if err?
                reject(err)
            else
                fs.writeFileSync(f, result)
                resolve()
        

module.exports = (local_files, callback) ->
    files_to_compress = local_files.filter( (f) -> f.split('.').pop() in COMPRESSABLE )
    SDKError.log("gzipping #{ files_to_compress.length } compressable files...")
    Promise.all(
        files_to_compress.map(processFile)
    ).then(callback)
