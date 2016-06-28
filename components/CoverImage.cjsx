React           = require 'react'
{ Classes }     = require 'shiny'

selectImageSize = (width, height, px_ratio) ->
    if width / height > 1
        comparison_dimension = width
    else
        comparison_dimension = height

    comparison_dimension = comparison_dimension * px_ratio

    if comparison_dimension > 1330
        return '2560'
    else if comparison_dimension > 668
        return '1280'
    else
        return '640'


module.exports = React.createClass
    displayName: 'CoverImage'

    propTypes:
        align       : React.PropTypes.oneOf(['center','top','right','bottom','left'])
        image       : React.PropTypes.oneOfType([
            React.PropTypes.object
            React.PropTypes.string
        ])
        intrinsic   : React.PropTypes.bool
        noscript    : React.PropTypes.bool

    getDefaultProps: -> {
        align       : 'center'
        intrinsic   : true
        noscript    : true
    }

    getInitialState: -> {
        __live: false
    }

    componentDidMount: ->
        console.log 'CoverImage::componentDidMount'
        @setState(__live: true)
        window.addEventListener('resize', @_updateSize)
        @_updateSize()

    componentWillUnmount: ->
        window.removeEventListener('resize', @_updateSize)

    _updateSize: ->
        if @isMounted()
            _el = React.findDOMNode(@refs.el)
            @setState
                width   : _el.offsetWidth
                height  : _el.offsetHeight

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

        bg_position = "#{ (x * 100).toFixed(0) }% #{ (y * 100).toFixed(0) }%"

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
        cx.add('intrinsic', @props.intrinsic)

        props =
            ref                     : 'el'
            className               : cx
            href                    : @props.link
            'data-is_empty'         : not main_image_url

        style =
            backgroundPosition: bg_position

        if @state.__live and image
            _size = selectImageSize(
                @state.width, @state.height, window?.devicePixelAspectRatio or 1
            )
            style.backgroundImage   = "url('#{ image.content[_size]?.url }')"
        else
            props[k] = v for k,v of (
                'data-src_640'          : src_640
                'data-src_1280'         : src_1280
                'data-src_2560'         : src_2560
                'data-aspect_ratio'     : aspect_ratio?.toFixed(3)
            )
            style.overflow = 'hidden'
        
        contents = <div className='_Image' style=style>
            { @props.children }
            {
                if @props.noscript and not @state.__live
                    <img src=main_image_url style={ width: '100%' } />
            }
        </div>

        if @props.link
            cx.set('link')
            return <a {...props}>{contents}</a>
        else
            return <div {...props}>{contents}</div>

