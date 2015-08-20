React   = require 'react'
moment  = require 'moment'

Cover = require './Cover'
{ Classes } = require 'shiny'


Card = React.createClass
    displayName: 'Card'

    propTypes:
        children    : React.PropTypes.oneOfType([
                React.PropTypes.element
                React.PropTypes.arrayOf(React.PropTypes.element)
            ]).isRequired
        link        : React.PropTypes.string
        id          : React.PropTypes.string
        title       : React.PropTypes.string
        className   : React.PropTypes.oneOfType([
                React.PropTypes.string
                React.PropTypes.object
            ])

    render: ->
        variants = new Classes()
        variants.add('full_cover', @props.children instanceof Cover)
        if @props.link
            tag = 'a'
            variants.set('link')
        else
            tag = 'div'
        return React.createElement tag,
            id          : @props.id
            className   : "Card #{ @props.className or '' } #{ variants }"
            href        : @props.link
            title       : @props.title
        , @props.children



module.exports = Card