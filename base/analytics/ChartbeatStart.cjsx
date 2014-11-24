React = require 'react'
_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'ChartbeatStart'
    render: ->
        _rawScript """
            window._sf_startpt=(new Date()).getTime();
        """