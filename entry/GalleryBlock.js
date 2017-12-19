// @flow

const React = require('react')
const shiny = require('shiny')

const r = React.createElement

function renderPlain (content) {
    return content.map( (image) => (
            r('figure', null,
                r('img', {
                    src: image.content['640'].url,
                    alt: image.alt_text,
                }),
                r('figcaption', null,
                    r('p', null, image.caption),
                    r('p', null, image.credit)
                )
            )
        )
    )
}

const GalleryBlock = (props) => {

    if (null == props.block.content) {
        return null
    }

    if (props.plain) {
        return r('div', ...renderPlain(props.block.content))
    }

    const cx = shiny('Block', 'GalleryBlock')

    const layout    = props.block.layout || {}
    const size      = layout.size || 'medium'
    const position  = layout.position || 'center'

    cx.set('size', size)
    if ('full' !== size) {
        cx.set('position', position)
    }

    const images = props.block.content.map( (image) => ({
        urls: {
            '128': image.content['128'].url,
            '640': image.content['640'].url,
            '1280': image.content['1280'].url,
            '2560': image.content['2560'].url,
        },
        credit          : image.credit,
        caption         : image.caption,
        alt_text        : image.alt_text,
        aspect_ratio    : image.original && image.original.height ? image.original.width / image.original.height : 1,
    }))

    return r('div', {
        id              : props.block.id,
        className       : cx,
        'data-images'   : JSON.stringify(images),
        'data-inline'   : props.inline,
    }, r('noscript', null, ...renderPlain(props.block.content)))
}

module.exports = GalleryBlock
