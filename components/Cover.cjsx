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
        variants.set('align', @props.align)
        if @props.link
            variants.set('link')
            <a className="Cover #{ variants }"
                style   = {backgroundImage: "url('#{ @props.image }')"}
                href    = @props.link
            >
                    {@props.children}
            </a>
        else
            <div className="Cover #{ variants }"
                style   = {backgroundImage: "url('#{ @props.image }')"}
            >
                    {@props.children}
            </div>