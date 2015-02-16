fs = require 'fs'
path = require 'path'

# Using a synchronous version of walk for simplicity
module.exports = walkSync = (dir, ignore=null) ->
    ignore ?= ['.']
    results = []
    list = fs.readdirSync(dir)
    for f in list
        unless f[0] in ignore or not ignore
            file = path.join(dir,f)
            stat = fs.statSync(file)
            if stat?.isDirectory()
                results.push(walkSync(file, ignore)...)
            else
                results.push(file)
    return results