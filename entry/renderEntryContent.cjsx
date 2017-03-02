React = require 'react'

EmbedBlock = require './EmbedBlock'
ImageBlock = require './ImageBlock'
ListBlock = require './ListBlock'
TextBlock = require './TextBlock'
GalleryBlock = require './GalleryBlock'

module.exports = (content, options={}) ->
    result = content?.map (block) ->

        if options.intercept?[block.type]
            return React.createElement(
                options.intercept[block.type],
                {
                    block: block
                    key: block.id
                    plain: options.plain
                }
            )

        switch block.type
            when 'text'
                return <TextBlock block=block key=block.id plain=options.plain />
            when 'image'
                return <ImageBlock block=block key=block.id plain=options.plain />
            when 'embed'
                return <EmbedBlock block=block key=block.id plain=options.plain />
            when 'list'
                return <ListBlock block=block key=block.id plain=options.plain />
            when 'gallery'
                return <GalleryBlock block=block key=block.id plain=options.plain />
            else
                return null

    if result and options.to_string
        result = result.map (block) ->
            React.renderToStaticMarkup(block)
        result = result.join('')

    return result