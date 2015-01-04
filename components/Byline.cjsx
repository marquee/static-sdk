React = require 'react'

module.exports = React.createClass
    displayName: 'Byline'
    getDefaultProps: -> {
        label: 'By '
        join: ', '
        and: '&'
    }
    render: ->
        names = @props.byline
        label = @props.label
        if names?.length > 0
            unless typeof names is 'string' or names.length is 1
                _last = names[names.length - 1]
                names[names.length - 1] = "#{ @props.and } #{ _last }"
                if names.length > 2
                    names = names.join(@props.join)
                else
                    names = names.join(' ')
        else
            label = null
        <div className='Byline'>
            <span className='_Label'>
                {label}
            </span>
            <span className='_Names'>
                {names}
            </span>
        </div>