React = require 'react'

module.exports = React.createClass
    displayName: 'ContactForm'
    render: ->
        if @props.meta
            meta = JSON.stringify(@props.meta)
        <div
            className           = 'ContactForm'
            data-publication    = global.config.PUBLICATION_SHORT_NAME
            data-commit         = global.build_info.commit
            data-host           = @props.host
            data-meta           = meta
        />