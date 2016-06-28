React = require 'react'

moment = require 'moment'

# http://momentjs.com/docs/#/displaying/
module.exports = React.createClass
    displayName: 'DateTime'

    propTypes:
        date        : React.PropTypes.oneOfType([
            React.PropTypes.number
            React.PropTypes.string
            React.PropTypes.object
        ]).isRequired
        format      : React.PropTypes.string
        label       : React.PropTypes.string
        relative    : React.PropTypes.oneOfType([
            React.PropTypes.bool
            React.PropTypes.number
            React.PropTypes.shape({
                days: React.PropTypes.number
            })
            React.PropTypes.shape({
                hours: React.PropTypes.number
            })
        ])

    getDefaultProps: -> {
        format      : 'YYYY-M-D'
        relative    : null
    }

    render: ->
        if @props.date
            _date = new Date(@props.date)
            _m_date = moment(_date)
            if @props.relative? and @props.relative isnt false
                if @props.relative.days
                    cutoff = @props.relative.days * 1000 * 60 * 60 * 24
                else if @props.relative.hours
                    cutoff = @props.relative.hours * 1000 * 60 * 60
                else if @props.relative is true
                    cutoff = Infinity
                else
                    cutoff = @props.relative
                if (new Date() - _date) < cutoff
                    date_str = _m_date.fromNow() 

            date_str ?= _m_date.format(@props.format)
            if @props.title_format
                date_title = _m_date.format(@props.title_format)
            date = _date.toISOString()
        <span className='DateTime' title=date_title>
            <span className='_Label'>{@props.label}</span>
            <time className='_Date' dateTime=date>
                {date_str}
            </time>
        </span>
