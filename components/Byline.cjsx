React = require 'react'

_joinFn = (names, options={}) ->

    unless names?.length > 0
        return ''

    if typeof names is 'string'
        return names

    if names[0].name?
        # The incoming names are entities
        names = (n.name for n in names)
    else
        # Make a copy because we're about to mutate it in-place.
        names = [names...]

    _join = options.join or ', '
    _and  = options.and or '&'
    _last = names[names.length - 1]
    names[names.length - 1] = "#{ _and } #{ _last }"
    if names.length > 2
        names = names.join(_join)
    else
        names = names.join(' ')
    return names



module.exports = React.createClass
    displayName: 'Byline'

    proptTypes:
        byline  : React.PropTypes.oneOfType([
                React.PropTypes.string
                React.PropTypes.arrayOf(React.PropTypes.string)
            ]).isRequired
        label   : React.PropTypes.string
        join    : React.PropTypes.string
        and     : React.PropTypes.string

    getDefaultProps: -> {
        label   : 'By '
        join    : ', '
        and     : '&'
    }

    render: ->
        label = @props.label
        names = _joinFn(@props.byline, and: @props.and, join: @props.join)
        unless names
            label = null
        <div className='Byline'>
            <span className='_Label'>
                {label}
            </span>
            <span className='_Names'>
                {names}
            </span>
        </div>


module.exports.join = _joinFn