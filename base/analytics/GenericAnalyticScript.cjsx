React = require 'react'
_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'GenericAnalyticsScript'
    render: ->
        return null unless @props.script
        _rawScript """
            (function() {
                #{ @props.script }
            })();
        """
