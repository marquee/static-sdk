React = require 'react'

module.exports = React.createClass
    displayName: '_Title'

    propTypes:
        title   : React.PropTypes.string
        level   : React.PropTypes.oneOf([1,2,3,4,5,6])
        link    : React.PropTypes.string

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