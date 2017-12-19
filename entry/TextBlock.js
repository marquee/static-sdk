// @flow

const NOAT      = require('./NOAT')
const React     = require('react')
const shiny     = require('shiny')
const url       = require('url')

const r = React.createElement

const TAG_MAP = {
    'emphasis'      : 'em.Annotation.-emphasis',
    'strong'        : 'strong.Annotation.-strong',
    'link'          : 'a.Annotation.-link',
    'small-caps'    : 'i.Annotation.-small_caps',
    'superscript'   : 'sup.Annotation.-superscript',
    'subscript'     : 'sub.Annotation.-subscript',
}

const TAG_MAP_PLAIN = {
    'emphasis'      : 'em',
    'strong'        : 'strong',
    'link'          : 'a',
    'small-caps'    : null,
    'superscript'   : 'sup',
    'subscript'     : 'sub',
}

function renderText (text, annotations, plain=false) {
    // Render the text content to HTML, applying annotations if any.
    text = new NOAT(text);

    const tag_map = plain ? TAG_MAP_PLAIN : TAG_MAP

    if (null != annotations) {
        annotations.forEach( (anno) => {
            const attrs = {}
            if ('link' === anno.type) {
                // Avoid trying to render links without a url specified.
                if (!anno.url) {
                    return
                }
                attrs.href = anno.url
                if (!plain) {
                    let _hostname
                    if (null != global && null != global.config) {
                        _hostname = global.config.HOST
                    }
                    if (null == _hostname && null != window) {
                        _hostname = window.location.hostname
                    }
                    if (null != _hostname) {
                        const _parsed = url.parse(anno.url)
                        if (null != _parsed.host && _parsed.host !== _hostname) {
                            attrs['data-external'] = true
                        }
                    }
                }
            }
            if (null != tag_map[anno.type]) {
                [tag, ...classes] = tag_map[anno.type].split('.')
                if (classes.length > 0 && !plain) {
                    attrs['class'] = classes.join(' ')
                }
                text.add(tag, anno.start, anno.end, attrs)
            }
        })
    }

    return text
}

function renderPlainText (text, annotations) {
    return renderText(text, annotations, true)
}


const TextBlock = (props) => {
    // Only render if `content` is not null.
    if (null == props.block.content) {
        return null
    }
    // Render the text content to HTML, applying annotations if any.
    const text = renderText(props.block.content, props.block.annotations, props.plain)

    // Choose the appropriate tag for the given block's role.
    // Unknown roles are ignored and not rendered.
    let blocktag = null;
    switch (props.block.role) {
        case 'paragraph':
            blocktag = 'p'
            break
        case 'quote':
            blocktag = 'blockquote'
            break
        case 'pre':
            blocktag = 'pre'
            break
        case 'heading':
            blocktag = `h${ (props.block.heading_level || 1) + 1}`
            break
        default:
            console.warn(`TextBlock got unknown role: ${ props.block.role }`)
            return null
    }

    if (props.plain) {
        return r(blocktag, {
            dangerouslySetInnerHTML: {
                __html: text.toString()
            }
        })
    }

    const cx = shiny('Block', 'TextBlock')
    cx.set('role', props.block.role)

    if (null != props.block.layout) {
        if (null != props.block.layout.align) {
            cx.add('align', props.block.layout.align)
        } else {
            cx.add('align', 'left')
        }
        if (null != props.block.layout.effect) {
            cx.add('effect', props.block.layout.effect)
        }
        if (null != props.block.highlight) {
            cx.add('highlight', props.block.highlight)
        }
    }

    return r(blocktag, {
        id                      : props.block.id,
        className               : cx,
        dangerouslySetInnerHTML : { __html: text.toString() }
    })
}

TextBlock.defaultProps = {
    plain: false
}

TextBlock.renderText        = renderText
TextBlock.renderPlainText   = renderPlainText

module.exports = TextBlock
