colors  = require 'colors/safe'
path    = require 'path'

module.exports = formatProjectPath = (p, f=null) ->
    p_parent = path.dirname(p) + '/'
    if f
        return "#{ colors.grey(p_parent) }#{ colors.grey.underline(p.replace(p_parent,'')) }#{ colors.green(f.replace(p,'')) }"
    return "#{ colors.grey(p_parent) }#{ colors.green(p.replace(p_parent,'')) }"
