const React     = require('react')
const url       = require('url')
const shiny     = require('shiny')

const r = React.createElement

const BlockCaption = require('./BlockCaption')

const ImageBlock = (props) => {
    if (null == props.block.content || null == props.block.content['640']) {
        return null
    }
    const { credit, caption } = props.block

    if (props.plain) {
        return r('figure', null,
            r('img', { src: props.block.content['640'] && props.block.content['640'].url }),
            r(BlockCaption, { caption, credit, plain: true })
        )
    }

    const src_128     = props.block.content['128'] ? props.block.content['128'].url : null
    const src_640     = props.block.content['640'] ? props.block.content['640'].url : null
    const src_1280    = props.block.content['1280'] ? props.block.content['1280'].url : null
    const src_2560    = props.block.content['2560'] ? props.block.content['2560'].url : null

    const srcset = [
        `${ src_128 } 128w`,
        `${ src_640 } 640w`,
        `${ src_1280 } 1280w`,
        `${ src_2560 } 2560w`,
    ]

    // $column-text    : 720px !default

    // https://jakearchibald.com/2015/anatomy-of-responsive-images/
    // img
    //     alt = "A red panda eating leaves"
    //     src ="panda-689.jpg"
    //     srcset ="
    //         panda-689.jpg 689w,
    //         panda-1378.jpg 1378w,
    //         panda-500.jpg 500w,
    //         panda-1000.jpg 1000w"
    //     sizes="
    //         (min-width: 1066px) 689px,
    //         (min-width: 800px) calc(75vw - 137px),
    //         (min-width: 530px) calc(100vw - 96px),
    //         100vw">


    const sizes = ['100vw']

    const layout    = props.block.layout || {}
    const size      = layout.size || 'medium'
    const position  = layout.position || 'center'
    cx = shiny('Block', 'ImageBlock')

    if ('small' === layout.size) {
        sizes.unshift(`(min-width: 360px) 360px`)
    } else if ('medium' === layout.size) {
        sizes.unshift(`(min-width: 720px) 720px`)
    } else if ('large' === layout.size) {
        sizes.unshift(`(min-width: 1440px) 1440px`)
    }

    return r('figure', { className: cx },
        r('div', { className: '_Content' },
            r('img', {
                src             : src_640,
                srcSet          : srcset.join(','),
                sizes           : sizes.join(','),
                alt             : props.block.alt_text,
                'data-src_128'  : src_128,
                'data-src_640'  : src_640,
                'data-src_1280' : src_1280,
                'data-src_2560' : src_2560,
            }),
            r(BlockCaption, { caption, credit, plain: false })
        )
    )
}

ImageBlock.defaultProps = {
    plain: false
}

module.exports = ImageBlock

//     render: ->

//         if @props.block.content?
//             src_2560 = @props.block.content['2560']?.url or undefined
//             src_1280 = @props.block.content['1280']?.url
//             src_640 = @props.block.content['640']?.url
//         unless src_640 and src_1280
//             # These two sizes are required. The large one should always be
//             # present, but is optional.
//             return null



//         variants = new Classes()

//         is_pinned = false
//         layout = @props.block.layout or {}
//         size = layout.size or 'medium'
//         position = layout.position or 'center'
//         effect = layout.effect or 'default'

//         aspect_ratio = @props.block.original?.width / (@props.block.original?.height or 1)

//         if effect is 'pin'
//             variants.set('pinned')
//             is_pinned = true
//             is_zoomable = false
//             image = <div className = '_Image' />
//         else
//             variants.set('size', size)
//             unless size is 'full'
//                 variants.set('position', position)
//             is_zoomable = true
//             image = <img className='_Image' />

//         if @props.block.link_to
//             _parsed = url.parse(@props.block.link_to)
//             image = <a
//                     className       = '_ImageLink'
//                     href            = @props.block.link_to
//                     data-external   = {_parsed.host and _parsed.host isnt global.config.HOST}
//                 >{image}</a>
//             is_zoomable = false
//         <figure
//             className           = "Block ImageBlock #{ variants }"
//             data-src_640        = src_640
//             data-src_1280       = src_1280
//             data-src_2560       = src_2560
//             data-aspect_ratio   = aspect_ratio.toFixed(3)
//             data-pinned         = is_pinned
//             data-zoomable       = is_zoomable
//             id                  = @props.block.id
//         >
//             <div className='_Content'>
//                 {image}
//                 <noscript>
//                     <img className='_Image' src=src_640 />
//                 </noscript>
//                 {
//                     if caption or credit
//                         <figcaption className='_Caption'>
//                             <span className='_CaptionText'>{caption}</span>
//                             <span className='_Credit'>{credit}</span>
//                         </figcaption>
//                 }
//             </div>
//         </figure>


// # <figure
// #     class="ImageBlock"
// #     data-src_1280="http://s3.amazonaws.com/marquee-test-akiaisur2rgicbmpehea/qs6clmjASJaPCa7o28rS_photo%20%282%29.JPG"
// #     data-has_caption="true"
// #     data-size="medium"
// #     data-aspect_ratio="1.33884297521"
// #     data-type="image"
// #     data-loaded="true"
// #     data-position="left"
// #     data-src_640="http://s3.amazonaws.com/marquee-test-akiaisur2rgicbmpehea/GFLnduOTciTaQ3uwgQ4Z_photo%20%282%29.JPG"
// #     id="image:53e354acc6fe4f0495fbb2c5b534cc9d"
// #     data-zoomed="false">
// #     <div class="Block_Content">
// #         <img class="ImageBlock_Image" alt="Rei-Ying Fang and Hong Xiang in the fields. (Photos by Karen Bender)"
// #             data-zoomable="true"
// #             src="http://s3.amazonaws.com/marquee-test-akiaisur2rgicbmpehea/GFLnduOTciTaQ3uwgQ4Z_photo%20%282%29.JPG"
// #             style="height: 399.598765431087px;">
// #         <figcaption class="Caption">
// #             Rei-Ying Fang and Hong Xiang in the fields. (Photos by Karen Bender)
// #         </figcaption>
// #     </div>
// # </figure>
