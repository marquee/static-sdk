React = require 'react'

{ Classes } = require 'shiny'

GalleryBlock = (props) ->

    cx = new Classes('Block GalleryBlock')

    layout = props.block.layout or {}
    size = layout.size or 'medium'
    position = layout.position or 'center'

    cx.set(size: size)
    cx.set(position: position) unless size is 'full'

    images = props.block.content?.map (image) ->
        return {
            urls:
                '128': image.content['128'].url
                '640': image.content['640'].url
                '1280': image.content['1280'].url
                '2560': image.content['2560'].url
            credit          : image.credit
            caption         : image.caption
            alt_text        : image.alt_text
            aspect_ratio    : if image.original?.height then image.original.width / image.original.height else 1
        }
    images ?= []
    <div id=props.block.id className=cx data-images=JSON.stringify(images)>
        <noscript>
            {
                images.map (image) ->
                    <img alt={ image.alt_text } key={ image.urls['640'] } src={ image.urls['640'] } />
            }
        </noscript>
    </div>

module.exports = GalleryBlock

