React = require 'react'

{ Classes } = require 'shiny'

module.exports = React.createClass
    displayName: 'ImageBlock'

    propTypes:
        block: React.PropTypes.object.isRequired

    render: ->

        if @props.block.content?
            src_2560 = @props.block.content['2560']?.url or undefined
            src_1280 = @props.block.content['1280']?.url
            src_640 = @props.block.content['640']?.url
        unless src_640 and src_1280
            # These two sizes are required. The large one should always be
            # present, but is optional.
            return null

        variants = new Classes()

        is_pinned = false
        layout = @props.block.layout or {}
        size = layout.size or 'medium'
        position = layout.position or 'center'
        effect = layout.effect or 'default'

        aspect_ratio = @props.block.original?.width / (@props.block.original?.height or 1)

        credit = @props.block.credit
        caption = @props.block.caption
        unless caption
            if @props.block.annotations
                for anno in @props.block.annotations
                    if anno.type is 'caption'
                        caption = anno.content
                        break

        if effect is 'pin'
            variants.set('pinned')
            is_pinned = true
            is_zoomable = false
            image = <div className = '_Image' />
        else
            variants.set('size', size)
            unless size is 'full'
                variants.set('position', position)
            is_zoomable = true
            image = <img className='_Image' />

        if @props.block.link_to
            image = <a className='_ImageLink' href=@props.block.link_to>{image}</a>
            is_zoomable = false
        <figure
            className           = "Block ImageBlock #{ variants }"
            data-src_640        = src_640
            data-src_1280       = src_1280
            data-src_2560       = src_2560
            data-aspect_ratio   = aspect_ratio.toFixed(3)
            data-pinned         = is_pinned
            data-zoomable       = is_zoomable
            id                  = @props.block.id
        >
            <div className='_Content'>
                {image}
                <noscript>
                    <img className='_Image' src=src_640 />
                </noscript>
                {
                    if caption or credit
                        <figcaption className='_Caption'>
                            <span className='_CaptionText'>{caption}</span>
                            <span className='_Credit'>{credit}</span>
                        </figcaption>
                }
            </div>
        </figure>


# <figure
#     class="ImageBlock"
#     data-src_1280="http://s3.amazonaws.com/marquee-test-akiaisur2rgicbmpehea/qs6clmjASJaPCa7o28rS_photo%20%282%29.JPG"
#     data-has_caption="true"
#     data-size="medium"
#     data-aspect_ratio="1.33884297521"
#     data-type="image"
#     data-loaded="true"
#     data-position="left"
#     data-src_640="http://s3.amazonaws.com/marquee-test-akiaisur2rgicbmpehea/GFLnduOTciTaQ3uwgQ4Z_photo%20%282%29.JPG"
#     id="image:53e354acc6fe4f0495fbb2c5b534cc9d"
#     data-zoomed="false">
#     <div class="Block_Content">
#         <img class="ImageBlock_Image" alt="Rei-Ying Fang and Hong Xiang in the fields. (Photos by Karen Bender)"
#             data-zoomable="true"
#             src="http://s3.amazonaws.com/marquee-test-akiaisur2rgicbmpehea/GFLnduOTciTaQ3uwgQ4Z_photo%20%282%29.JPG"
#             style="height: 399.598765431087px;">
#         <figcaption class="Caption">
#             Rei-Ying Fang and Hong Xiang in the fields. (Photos by Karen Bender)
#         </figcaption>
#     </div>
# </figure>
