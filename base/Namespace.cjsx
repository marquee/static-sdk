React   = require 'react'

module.exports = React.createClass
    displayName: 'Namespace'

    propTypes:
        namespace   : React.PropTypes.string.isRequired

    getDefaultProps: -> {
        namespace: 'Marquee'
    }

    render: ->
        <script dangerouslySetInnerHTML={
            __html: """window[#{ @props.namespace }] = {};"""
        }/>
