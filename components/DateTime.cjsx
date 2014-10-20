React = require 'react'

moment = require 'moment'

# http://momentjs.com/docs/#/displaying/
module.exports = React.createClass
    displayName: 'DateTime'
    getDefaultProps: -> {
        format: 'YYYY-M-D'
    }
    render: ->
        if @props.date
            date_str = moment(@props.date).format(@props.format)
            date = @props.date.toISOString()
        <span className='DateTime'>
            <span className='_Label'>{@props.label}</span>
            <time className='_Date' dateTime=date>
                {date_str}
            </time>
        </span>
