React = require 'react'

module.exports = React.createClass
    displayName: 'CoverCredit'
    render: ->
        <div className='CoverCredit'>
            {@props.children}
        </div>
