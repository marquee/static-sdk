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
    cx.set({
        size        : size,
        position    : position,
    })

    if ('small' === layout.size) {
        sizes.unshift(`(min-width: 360px) 360px`)
    } else if ('medium' === layout.size) {
        sizes.unshift(`(min-width: 720px) 720px`)
    } else if ('large' === layout.size) {
        sizes.unshift(`(min-width: 1440px) 1440px`)
    }

    let image_el = r('img', {
        className       : '_Image',
        src             : src_640,
        srcSet          : srcset.join(','),
        sizes           : sizes.join(','),
        alt             : props.block.alt_text,
    })

    if (null != props.block.link && props.block.link.length > 0) {
        cx.add('link')
        image_el = r('a', {
            style: { display: 'block' },
            href: props.block.link,
            className: '_Link',
        }, image_el)
    }

    return r('figure', { id: props.block.id, className: cx },
        r('div', { className: '_Content', href: props.block.link },
            image_el,
            r(BlockCaption, { caption, credit, plain: false })
        )
    )
}

ImageBlock.defaultProps = {
    plain: false
}

module.exports = ImageBlock
