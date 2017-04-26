const React     = require('react')
const shiny     = require('shiny')

const r = React.createElement

const ContentImage = (props) => {
    if (null == props.src.content || null == props.src.content['640']) {
        return null
    }

    if (props.plain) {
        return r('img', { src: props.src.content['640'] && props.src.content['640'].url })
    }

    const src_128     = props.src.content['128'] ? props.src.content['128'].url : null
    const src_640     = props.src.content['640'] ? props.src.content['640'].url : null
    const src_1280    = props.src.content['1280'] ? props.src.content['1280'].url : null
    const src_2560    = props.src.content['2560'] ? props.src.content['2560'].url : null

    const srcset = [
        `${ src_128 } 128w`,
        `${ src_640 } 640w`,
        `${ src_1280 } 1280w`,
        `${ src_2560 } 2560w`,
    ]

    cx = shiny('ContentImage')
    cx.add('cover', props.cover)
    const sizes = ['100vw']
    sizes.unshift(`(min-width: 360px) 360px`)
    sizes.unshift(`(min-width: 720px) 720px`)
    sizes.unshift(`(min-width: 1440px) 1440px`)

    return r('img', {
        className       : cx,
        src             : src_640,
        srcSet          : srcset.join(','),
        sizes           : sizes.join(','),
        alt             : props.src.alt_text,
        'data-src_128'  : src_128,
        'data-src_640'  : src_640,
        'data-src_1280' : src_1280,
        'data-src_2560' : src_2560,
    })
}

ContentImage.defaultProps = {
    plain: false,
    cover: false,
}

module.exports = ContentImage
