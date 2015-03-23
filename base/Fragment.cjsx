###
A wrapper for easier construction of HTML fragments for async loading, eg PJAX.
###

React   = require 'react'

module.exports = React.createClass
    displayName: 'Fragment'

    propTypes:
        children    : React.PropTypes.element.isRequired
        className   : React.PropTypes.oneOfType([
                React.PropTypes.string
                React.PropTypes.object
            ])
        id          : React.PropTypes.string

    getDefaultProps: -> {
        className: 'Fragment__'
    }

    render: ->
        <div id=@props.id className=@props.className>
            {@props.children}
        </div>
