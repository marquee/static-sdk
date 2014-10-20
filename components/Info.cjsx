React = require 'react'

module.exports = React.createClass
    displayName: '_Info'
    render: ->
        <div className='_Info'>{@props.children}</div>
