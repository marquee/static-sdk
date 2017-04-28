// @flow
const fs    = require('fs')
const path  = require('path')

// A synchronous version of walk for simplicity
module.exports = function walkSync (dir/*: string*/, ignore/*: ?Array<string>*/=['.'])/*: Array<string>*/ {
    const results = []
    fs.readdirSync(dir).forEach( f => {
        if (null == ignore || -1 === ignore.indexOf(f[0]) ) {
            const file = path.join(dir, f)
            const stat = fs.statSync(file)
            if (null != stat && stat.isDirectory()) {
                results.push(...walkSync(file, ignore))
            } else {
                results.push(file)
            }
        }
    })
    return results
}