React = require 'react'
{ Classes } = require 'shiny'


module.exports = React.createClass
    displayName: 'CardGrid'

    propTypes:
        columns: React.PropTypes.oneOf([
                1,2,3,4
            ]).isRequired
        double_first        : React.PropTypes.bool
        id                  : React.PropTypes.string
        respond_to_viewport : React.PropTypes.bool
        vary                : React.PropTypes.bool

    getDefaultProps: -> {
        columns             : 3
        double_first        : false
        respond_to_viewport : false
        vary                : true
    }

    render: ->
        cx = new Classes('CardGrid__', @props.className)
        cx.set('columns'                , @props.columns)
        cx.add('double_first'           , @props.double_first)
        cx.add('vary'                   , @props.vary)
        cx.add('respond_to_viewport'    , @props.respond_to_viewport)

        items = @props.children or @props.items

        <div className=cx id=@props.id>
            {
                React.Children.map items, (item, i) =>
                    <div className="_GridItem__" key="#{ @props.id }_#{ i }">
                        { item }
                    </div>
            }
        </div>
