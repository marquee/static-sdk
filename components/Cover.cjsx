React = require 'react'

#TODO: responsive, set image URL based on size

{ Classes } = require 'shiny'

module.exports = React.createClass
    displayName: 'Cover'
    getDefaultProps: -> {
        align: 'center'
    }
    render: ->
        variants = new Classes(@props.className)
        if @props.link
            tag = React.DOM.a
            variants.set('link')
        else
            tag = React.DOM.div
        variants.set('align', @props.align)
        <tag className="Cover #{ variants }"
            style   = {backgroundImage: "url('#{ @props.image }')"}
            href    = @props.link
        >
                {@props.children}
        </tag>