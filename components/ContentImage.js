// @flow

const React     = require('react')
const shiny     = require('shiny')

const r = React.createElement

const ContentImage = (props/*: { src: ?Object, cover: boolean, max_size: ?number }*/) => {
    if (null == props.src || null == props.src.content || null == props.src.content['640']) {
        return null
    }

    const alt_text = props.src.alt_text

    if (props.plain) {
        return r('img', { src: props.src.content['640'] && props.src.content['640'].url })
    }

    const srcset = []

    const src_128     = props.src.content['128'] ? props.src.content['128'].url : null
    const src_640     = props.src.content['640'] ? props.src.content['640'].url : null
    const src_1280    = props.src.content['1280'] ? props.src.content['1280'].url : null
    const src_2560    = props.src.content['2560'] ? props.src.content['2560'].url : null

    if (null != src_128) {
        srcset.unshift(`${ src_128 } 128w`)
    }
    if (null != src_640) {
        srcset.unshift(`${ src_640 } 640w`)
    }
    if (null != src_1280) {
        srcset.unshift(`${ src_1280 } 1280w`)
    }
    if (null != src_2560) {
        srcset.unshift(`${ src_2560 } 2560w`)
    }

    const cx = shiny('ContentImage')
    cx.add('cover', props.cover)
    const sizes = ['100vw']
    if (null == props.max_size || props.max_size >= 640) {
        sizes.unshift(`(min-width: 640px) 640px`)
    }
    
    if (null == props.max_size || props.max_size >= 1280) {
        sizes.unshift(`(min-width: 1280px) 1280px`)
    }

    if (null == props.max_size || props.max_size >= 2560) {
        sizes.unshift(`(min-width: 2560px) 2560px`)
    }

    const style = {}
    if (props.cover && null != props.src && null != props.src.focal_point) {
        style.objectPosition = `${ props.src.focal_point.x * 100 }% ${ props.src.focal_point.y * 100 }%`
    }

    return r('img', {
        className       : cx,
        src             : src_640,
        srcSet          : srcset.join(','),
        sizes           : sizes.join(','),
        alt             : alt_text,
        style           : style,
        'data-src_128'  : src_128,
        'data-src_640'  : src_640,
        'data-src_1280' : src_1280,
        'data-src_2560' : src_2560,
    })
}

ContentImage.defaultProps = {
    plain: false,
    cover: false,
    max_size: null,
}

module.exports = ContentImage
