React = require 'react'

module.exports = React.createClass
    displayName: '_Category'

    propTypes:
        category: React.PropTypes.string

    render: ->
        <span className='_Category'>{@props.category}</span>
