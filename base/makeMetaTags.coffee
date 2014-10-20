React = require 'react'

module.exports = (tags) ->
    _tags = []
    for name, content of tags
        if content
            _tags.push <meta name=name content=content key=name />
    return _tags