React = require 'react'

{ Classes } = require 'shiny'

module.exports = React.createClass
    displayName: '_Title'

    propTypes:
        title   : React.PropTypes.oneOfType([React.PropTypes.string, React.PropTypes.array])
        level   : React.PropTypes.oneOf([1,2,3,4,5,6])
        link    : React.PropTypes.string

    getDefaultProps: -> {
        level: 3
    }
    render: ->
        tag = "h#{ @props.level }"
        cx = new Classes('_Title', @props.className)
        if @props.link
            contents = <a className='_TitleLink' href=@props.link>{@props.title}</a>
            cx.add('-link')
        else
            contents = @props.title
        return React.createElement(tag, className: cx, contents)