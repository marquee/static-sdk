React = require 'react'

module.exports = React.createClass
    displayName: 'ReadingProgress'
    render: ->
        <div className='ReadingProgress'>
            <span className='_ProgressBar'></span>
        </div>