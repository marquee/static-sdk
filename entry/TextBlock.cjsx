React = require 'react'

NOAT = require './NOAT'
{ Classes } = require 'shiny'

TAG_MAP =
    emphasis: 'em'
    strong: 'strong'
    link: 'a'


module.exports = React.createClass
    displayName: 'TextBlock'
    render: ->
        text = new NOAT(@props.block.content)
        @props.block.annotations.forEach (anno) ->
            attrs = {}
            attrs.href = anno.url if anno.type is 'link'
            text.add(TAG_MAP[anno.type], anno.start, anno.end, attrs)
        switch @props.block.role
            when 'paragraph'
                blocktag = React.DOM.p
            when 'quote'
                blocktag = React.DOM.blockquote
            when 'pre'
                blocktag = React.DOM.pre
            when 'heading'
                blocktag = React.DOM["h#{ @props.block.heading_level or 1 + 1}"]
            else
                console.warn("TextBlock got unknown role: #{ @props.block.role }")
                return null

        variants = new Classes()

        variants.add('align', @props.block.layout?.align or 'left')
        variants.add('effect', @props.block.layout.effect) if @props.block.layout?.effect
        variants.add('role', @props.block.role)

        <blocktag className="Block TextBlock #{ variants }" dangerouslySetInnerHTML={__html: text.toString()} />