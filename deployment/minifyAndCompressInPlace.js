
const zlib        = require('zlib')
const fs          = require('fs')
const SDKError    = require('../compiler/SDKError')


const COMPRESSABLE = ['js', 'css', 'svg', 'html', 'txt', 'json', 'xml']

function processFile (f) {
    return new Promise( (resolve, reject) => {
        zlib.gzip(fs.readFileSync(f), (err, result) => {
            if (err) {
                reject(err)
            } else {
                fs.writeFileSync(f, result)
                resolve()
            }
        })
    })
}
        

module.exports = function (local_files, callback) {
    const files_to_compress = local_files.filter( f => COMPRESSABLE.indexOf(f.split('.').pop()) > -1 )
    SDKError.log(`gzipping ${ files_to_compress.length } compressable files...`)
    Promise.all(
        files_to_compress.map(processFile)
    ).then(callback)
}
