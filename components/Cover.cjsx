React = require 'react'

#TODO: responsive, set image URL based on size

{ Classes } = require 'shiny'

module.exports = React.createClass
    displayName: 'Cover'

    propTypes:
        align       : React.PropTypes.string
        className   : React.PropTypes.string
        children    : React.PropTypes.element
        image       : React.PropTypes.oneOfType([
                React.PropTypes.string
                React.PropTypes.object
            ])
        link        : React.PropTypes.string

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