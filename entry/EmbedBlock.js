const BlockCaption  = require('./BlockCaption')
const React         = require('react')
const shiny         = require('shiny')
const UglifyJS      = require('uglify-js')
const url           = require('url')

const r = React.createElement

function parseVideoURL (_url) {
    const parsed_url = url.parse(_url, true)

    if (!parsed_url.hostname) {
        return null
    }

    switch (parsed_url.hostname.replace('www.','')) {
        case 'youtube.com':
            return `//www.youtube.com/embed/${ parsed_url.query.v }?modestbranding=1`
            break
        case 'youtu.be':
            return `//www.youtube.com/embed${ parsed_url.pathname }?modestbranding=1`
            break
        case 'vimeo.com':
            return `//player.vimeo.com/video${ parsed_url.pathname }`
            break
        case 'player.vimeo.com':
            return _url
            break
    }
    return null
}

const EmbedCard = (props) => (
    r('a', { className: props.plain ? null : 'EmbedCard', href: props.url },
        r('img', { src: props.thumbnail_url }),
        r('h1', null, props.title),
        r('p', null, props.description),
    )
)

const EmbedMarkup = (props) => (
    r('div', {
        dangerouslySetInnerHTML: {
            __html: props.markup
        }
    })
)

const EmbedVideo = (props) => {
    if (props.plain) {
        return r('iframe', {
            src                     : props.url,
            frameBorder             : 0,
            allowFullScreen         : true,
        })
    }
    return r('div', { className: '_EmbedWrapper' },
        r('iframe', {
            id                  : props.id,
            className           : '_EmbedFrame',
            'data-frame_src'    : props.url,
            frameBorder         : 0,
            allowFullScreen     : true,
        }),
        r('script', {
            dangerouslySetInnerHTML: {
                __html: UglifyJS.minify(`
                    ;(function(window){
                        window.addEventListener('load', function(){
                            var target = document.getElementById('${ props.id }');
                            if (target) {
                                target.setAttribute('src', target.dataset.frame_src);
                            }
                        });
                    })(window);
                `, { fromString: true }).code
            }
        })
    )
}

const EmbedBlock = (props) => {
    if (null == props.block.content) {
        return null
    }

    const tag_props = {}

    const { credit, caption } = props.block

    if (!props.plain) {
        const layout    = props.block.layout || {}
        const size      = layout.size || 'medium'
        const position  = layout.position || 'center'
        tag_props.className = shiny('Block', 'EmbedBlock')
        tag_props.className.set('size', size)
        if ('full' !== size) {
            tag_props.className.set('position', position)
        }
        tag_props.id = props.block.id
    }

    let embed_content
    if (null != props.block.embedly_result) {
        if (null != props.block.embedly_result.html) {
            embed_content = r(EmbedMarkup, { plain: props.plain, markup: props.block.embedly_result.html })
            if (!props.plain) { tag_props.className.set('source', 'embedly_html') }
        } else {
            embed_content = r(EmbedCard, props.block.embedly_result)
            if (!props.plain) { tag_props.className.set('source', 'embedly_link') }
        }
    } else {
        const embed_video_url = parseVideoURL(props.block.content)
        if (embed_video_url) {
            const embed_id = `${ props.block.id }_content`
            embed_content = r(EmbedVideo, { plain: props.plain, url: embed_video_url, id: embed_id })
            if (!props.plain) { tag_props.className.set('source', 'video') }
        } else {
            embed_content = r(EmbedMarkup, { plain: props.plain, markup: props.block.content })
            if (!props.plain) { tag_props.className.set('source', 'markup') }
        }
    }

    if (props.plain) {
        return r('figure', null,
            embed_content,
            r(BlockCaption, { plain: props.plain, caption: caption, credit: credit })
        )
    }
    return r('figure', tag_props,
        r('div', { className: '_Content' },
            embed_content,
            r(BlockCaption, { plain: props.plain, caption: caption, credit: credit }),
        )
    )
}

EmbedBlock.defaultProps = {
    plain: false
}

EmbedBlock.parseVideoURL = parseVideoURL

module.exports = EmbedBlock