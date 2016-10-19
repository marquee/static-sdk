React = require 'react'

{ Classes } = require 'shiny'

TextBlock = require './TextBlock'


module.exports = React.createClass
    displayName: 'ListBlock'
    render: ->

        unless @props.plain
            cx = new Classes('Block ListBlock')
            cx.add('role', @props.block.role)


        Tag = if @props.block.role is 'ordered' then 'ol' else 'ul'

        <Tag
            className   = cx
        >
            {
                @props.block.content.map (subblock, i) =>
                    <li key=i dangerouslySetInnerHTML={
                        __html: TextBlock.renderText(
                            subblock.text,
                            subblock.annotations,
                            @props.plain
                        )
                    } />
            }
        </Tag>



