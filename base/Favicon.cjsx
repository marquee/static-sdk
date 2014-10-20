React   = require 'react'
mime    = require 'mime'

module.exports = React.createClass
    displayName: 'Favicon'
    getDefaultProps: -> {
        name: 'favicon.ico'
    }
    render: ->
        <link
            rel     = 'icon'
            type    = mime.lookup(@props.name)
            href    = "#{ global.ASSET_URL }#{ @props.name }"
        />