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


module.exports = React.createClass
    displayName: 'TextBlock'

    propTypes:
        block: React.PropTypes.object.isRequired

    render: ->
        # Only render if `content` is not null.
        return null unless @props.block.content?

        # Render the text content to HTML, applying annotations if any.
        text = new NOAT(@props.block.content)
        @props.block.annotations?.forEach (anno) ->
            attrs = {}
            if anno.type is 'link'
                # Avoid trying to render links without a url specified.
                unless anno.url
                    return
                attrs.href = anno.url
                _parsed = url.parse(anno.url)
                if _parsed.host and _parsed.host isnt global.config.HOST
                    attrs['data-external'] = true
            if TAG_MAP[anno.type]
                [tag, classes...] = TAG_MAP[anno.type].split('.')
                if classes.length > 0
                    attrs['class'] = classes.join(' ') 
                text.add(tag, anno.start, anno.end, attrs)

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

        variants = new Classes()

        variants.add('align', @props.block.layout?.align or 'left')
        variants.add('effect', @props.block.layout.effect) if @props.block.layout?.effect
        variants.add('role', @props.block.role)

        <blocktag
            id          = @props.block.id
            className   = "Block TextBlock #{ variants }"
            dangerouslySetInnerHTML={__html: text.toString()} />
