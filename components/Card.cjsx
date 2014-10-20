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
            tag = React.DOM.a
            variants.set('link')
        else
            tag = React.DOM.div
        <tag
            id          = @props.id
            className   = "Card #{ @props.className or '' } #{ variants }"
            href        = @props.link
        >
            {@props.children}
        </tag>


Card.Summary = React.createClass
    displayName: '_Summary'
    render: ->
        <p className='_Summary'>
            {@props.summary}
        </p>


Card.Title = React.createClass
    displayName: '_Title'
    getDefaultProps: -> {
        level: 3
    }
    render: ->
        tag = React.DOM["h#{ @props.level }"]
        if @props.link
            contents = <a className='_TitleLink' href=@props.link>{@props.title}</a>
        else
            contents = @props.title
        <tag className='_Title'>
            {contents}
        </tag>


Card.Info = React.createClass
    displayName: '_Info'
    render: ->
        <div className='_Info'>{@props.children}</div>


Card.Category = React.createClass
    displayName: '_Category'
    render: ->
        <span className='_Category'>{@props.category}</span>



module.exports = Card