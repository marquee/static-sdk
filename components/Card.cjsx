React   = require 'react'
moment  = require 'moment'

Cover = require './Cover'
{ Classes } = require 'shiny'


Card = React.createClass
    displayName: 'Card'
    render: ->
        variants = new Classes()
        variants.add('full_cover', @props.children instanceof Cover)
        if @props.link
            tag = 'a'
            variants.set('link')
        else
            tag = 'div'
        <tag
            id          = @props.id
            className   = "Card #{ @props.className or '' } #{ variants }"
            href        = @props.link
        >
            {@props.children}
        </tag>



module.exports = Card