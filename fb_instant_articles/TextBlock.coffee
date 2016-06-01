React   = require 'react'
NOAT    = require '../entry/NOAT'



TAG_MAP_PLAIN =
    'emphasis'      : 'em'
    'strong'        : 'strong'
    'link'          : 'a'
    'small-caps'    : null
    'superscript'   : 'sup'
    'subscript'     : 'sub'



module.exports = React.createClass
    displayName: 'TextBlock'

    propTypes:
        block   : React.PropTypes.object.isRequired

    render: ->
        # Only render if `content` is not null.
        return null unless @props.block.content?

        # Render the text content to HTML, applying annotations if any.
        text = new NOAT(@props.block.content)

        tag_map = TAG_MAP_PLAIN

        @props.block.annotations?.forEach (anno) =>
            attrs = {}
            if anno.type is 'link'
                # Avoid trying to render links without a url specified.
                unless anno.url
                    return
                attrs.href = anno.url

            if tag_map[anno.type]
                [tag, classes...] = tag_map[anno.type].split('.')
                text.add(tag, anno.start, anno.end, attrs)

        # Choose the appropriate tag for the given block's role.
        # Unknown roles are ignored and not rendered.
        switch @props.block.role
            when 'paragraph'
                blocktag = 'p'
            when 'quote'
                blocktag = 'aside'
            when 'pre'
                blocktag = 'pre'
            when 'heading'
                blocktag = "h#{ @props.block.heading_level or 1 + 1}"
            else
                console.warn("TextBlock got unknown role: #{ @props.block.role }")
                return null

        return React.createElement(blocktag, dangerouslySetInnerHTML:{ __html: text.toString() })