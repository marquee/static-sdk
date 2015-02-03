React = require 'react'

EmbedBlock = require './EmbedBlock'
ImageBlock = require './ImageBlock'
TextBlock = require './TextBlock'

module.exports = (content) ->
    return content.map (block) ->
        switch block.type
            when 'text'
                return <TextBlock block=block key=block.id />
            when 'image'
                return <ImageBlock block=block key=block.id />
            when 'embed'
                return <EmbedBlock block=block key=block.id />
            else
                return null
