React = require 'react'

module.exports = React.createClass
    displayName: '_Summary'
    render: ->
        <p className='_Summary'>
            {@props.summary}
        </p>