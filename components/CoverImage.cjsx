React = require 'react'

{ Classes } = require 'shiny'

module.exports = React.createClass
    displayName: 'CoverImage'
    propTypes:
        align: React.PropTypes.oneOf(['center','top','right','bottom','left'])
    getDefaultProps: -> {
        align: 'center'
        size: null
        noscript: true
    }
    render: ->
        cx = new Classes('CoverImage', @props.className)

        _x = 0.5
        _y = 0.5
        switch @props.align
            when 'top'
                _y = 0
            when 'right'
                _x = 1
            when 'bottom'
                _y = 1
            when 'left'
                _x = 0

        image = @props.image
        image = image._obj if image?._obj


        if image?.focal_point
            { x, y } = image.focal_point
            cx.set('align', 'focal_point')
        else
            cx.set('align', @props.align)
        x = _x unless x?
        y = _y unless y?

        bg_position = "#{ x * 100 }% #{ y * 100}%"

        if image?.content?
            src_2560        = image.content['2560']?.url or undefined
            src_1280        = image.content['1280']?.url
            src_640         = image.content['640']?.url
            main_image_url  = src_640
            aspect_ratio    = image.original?.width / (image.original?.height or 1)
        else
            main_image_url  = image
            src_2560        = image
            src_1280        = image
            src_640         = image


        cx.add('is_empty', not main_image_url)

        props =
            className               : cx
            style:
                backgroundPosition      : bg_position
                display                 : 'block'
                height                  : '100%'
            href                    : @props.link
            'data-is_empty'         : not main_image_url
            'data-src_640'          : src_640
            'data-src_1280'         : src_1280
            'data-src_2560'         : src_2560
            'data-aspect_ratio'     : aspect_ratio?.toFixed(3)

        contents = [@props.children]
        if @props.noscript and main_image_url
            contents.unshift <noscript>
                    <img src=main_image_url />
                </noscript>

        if @props.link
            cx.set('link')
            return <a {...props}>{contents}</a>
        else
            return <div {...props}>{contents}</div>