React = require 'react'

module.exports = React.createClass
    displayName: '_Category'
    render: ->
        <span className='_Category'>{@props.category}</span>
