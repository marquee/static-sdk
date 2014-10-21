fs = require 'fs'
path = require 'path'

# Using a synchronous version of walk for simplicity
module.exports = walkSync = (dir) ->
    results = []
    list = fs.readdirSync(dir)
    for f in list
        file = path.join(dir,f)
        stat = fs.statSync(file)
        if stat?.isDirectory()
            results.push(walkSync(file)...)
        else
            unless f[0] is '.'
                results.push(file)
    return results