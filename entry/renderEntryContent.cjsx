React = require 'react'

EmbedBlock = require './EmbedBlock'
ImageBlock = require './ImageBlock'
TextBlock = require './TextBlock'

module.exports = (content, options={}) ->
    result = content?.map (block) ->
        switch block.type
            when 'text'
                return <TextBlock block=block key=block.id plain=options.plain />
            when 'image'
                return <ImageBlock block=block key=block.id plain=options.plain />
            when 'embed'
                return <EmbedBlock block=block key=block.id plain=options.plain />
            else
                return null

    if result and options.to_string
        result = result.map (block) ->
            React.renderToStaticMarkup(block)
        result = result.join('')

    return result