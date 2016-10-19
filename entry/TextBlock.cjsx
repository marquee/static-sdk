React = require 'react'

url = require 'url'

NOAT = require './NOAT'
{ Classes } = require 'shiny'

TAG_MAP =
    'emphasis'      : 'em.Annotation.-emphasis'
    'strong'        : 'strong.Annotation.-strong'
    'link'          : 'a.Annotation.-link'
    'small-caps'    : 'i.Annotation.-small_caps'
    'superscript'   : 'sup.Annotation.-superscript'
    'subscript'     : 'sub.Annotation.-subscript'

TAG_MAP_PLAIN =
    'emphasis'      : 'em'
    'strong'        : 'strong'
    'link'          : 'a'
    'small-caps'    : null
    'superscript'   : 'sup'
    'subscript'     : 'sub'


renderText = (text, annotations, plain=false) ->
    # Render the text content to HTML, applying annotations if any.
    text = new NOAT(text)

    tag_map = if plain then TAG_MAP_PLAIN else TAG_MAP

    annotations?.forEach (anno) =>
        attrs = {}
        if anno.type is 'link'
            # Avoid trying to render links without a url specified.
            unless anno.url
                return
            attrs.href = anno.url
            unless plain
                _hostname = global?.config?.HOST or window?.location.hostname
                if _hostname and not plain
                    _parsed = url.parse(anno.url)
                    if _parsed.host and _parsed.host isnt _hostname
                        attrs['data-external'] = true
        if tag_map[anno.type]
            [tag, classes...] = tag_map[anno.type].split('.')
            if classes.length > 0 and not plain
                attrs['class'] = classes.join(' ') 
            text.add(tag, anno.start, anno.end, attrs)

    return text

renderPlainText = (text, annotations) -> renderText(text, annotations, true)



module.exports = React.createClass
    displayName: 'TextBlock'

    getDefaultProps: -> {
        plain: false
    }

    propTypes:
        block   : React.PropTypes.object.isRequired
        plain   : React.PropTypes.bool.isRequired

    render: ->
        # Only render if `content` is not null.
        return null unless @props.block.content?

        # Render the text content to HTML, applying annotations if any.
        text = renderText(@props.block.content, @props.block.annotations, @props.plain)

        # Choose the appropriate tag for the given block's role.
        # Unknown roles are ignored and not rendered.
        switch @props.block.role
            when 'paragraph'
                blocktag = 'p'
            when 'quote'
                blocktag = 'blockquote'
            when 'pre'
                blocktag = 'pre'
            when 'heading'
                blocktag = "h#{ @props.block.heading_level or 1 + 1}"
            else
                console.warn("TextBlock got unknown role: #{ @props.block.role }")
                return null

        if @props.plain
            return React.createElement(blocktag, dangerouslySetInnerHTML:{__html: text.toString()})

        variants = new Classes()

        variants.add('align', @props.block.layout?.align or 'left')
        variants.add('effect', @props.block.layout.effect) if @props.block.layout?.effect
        variants.add('role', @props.block.role)

        return React.createElement(blocktag,
            id                      : @props.block.id
            className               : "Block TextBlock #{ variants }"
            dangerouslySetInnerHTML : {__html: text.toString()}
        )

module.exports.renderText = renderText
module.exports.renderPlainText = renderPlainText