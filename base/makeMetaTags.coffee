React = require 'react'

module.exports = (meta) ->
    tags = []
    for k,v of meta
        if k.split(':')[0] is 'og'
            tags.push(<meta property=k content=v key=k />)
        else
            tags.push(<meta name=k content=v key=k />)
    return tags