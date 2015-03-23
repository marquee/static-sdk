###
A very simple base element with the bare minimum needed to create a complete
page.
###

React   = require 'react'


module.exports = React.createClass
    displayName: 'BareBase'

    propTypes:
        children    : React.PropTypes.arrayOf(React.PropTypes.element).isRequired
        className   : React.PropTypes.string
        title       : React.PropTypes.string

    getDefaultProps: -> {
        className   : ''
        title       : ''
    }

    render: ->
        <html>
            <head>
                <title>{ @props.title }</title>
                <meta charSet='utf-8' />
            </head>
            <body className=@props.className>
                {@props.children}
            </body>
        </html>
