React = require 'react'

module.exports = React.createClass
    displayName: '_Title'
    getDefaultProps: -> {
        level: 3
    }
    render: ->
        tag = "h#{ @props.level }"
        if @props.link
            contents = <a className='_TitleLink' href=@props.link>{@props.title}</a>
        else
            contents = @props.title
        <tag className='_Title'>
            {contents}
        </tag>