React = require 'react'

module.exports = React.createClass
    displayName: 'EmbedBlock'
    render: ->
        # TODO: render annotations, layout

        <div className='EmbedBlock' id=@props.block.id>
            <div className='_BlockContent'>
                {@props.block.content}
            </div>
        </div>

