React = require 'react'

module.exports = (tags) ->
    _tags = []
    for property, content of tags
        if content
            _tags.push <meta property=property content=content key=property />
    return _tags