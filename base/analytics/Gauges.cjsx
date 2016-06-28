React = require 'react'
_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'Gauges'

    propTypes:
        id: React.PropTypes.string

    render: ->
        return null unless @props.id

        <script
            id              = 'gauges-tracker'
            type            = 'text/javascript'
            data-site-id    = @props.id
            data-track-path = 'https://track.gaug.es/track.gif'
            src             = 'https://d36ee2fcip1434.cloudfront.net/track.js'
            async           = true
        />