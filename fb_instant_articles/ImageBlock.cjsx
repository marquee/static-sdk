React = require 'react'



module.exports = React.createClass
    displayName: 'ImageBlock'

    propTypes:
        block       : React.PropTypes.object.isRequired
        comments    : React.PropTypes.bool
        likes       : React.PropTypes.bool

    getDefaultProps: -> {
        comments    : true
        likes       : true
    }

    render: ->

        src_1280 = @props.block.content?['1280']?.url
        unless src_1280
            return null

        credit = @props.block.credit
        caption = @props.block.caption

        feedback = []
        if @props.likes
            feedback.push('fb:likes')
        if @props.comments
            feedback.push('fb:comments')

        <figure data-feedback={ feedback.join(',') }>
            <img src=src_1280 />
            {
                if caption or credit
                    <figcaption>
                        {
                            if caption
                                <h1>{caption}</h1>
                        }
                        {
                            if credit
                                <cite>{ credit }</cite>
                        }
                    </figcaption>
            }
        </figure>