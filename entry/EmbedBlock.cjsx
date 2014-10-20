React = require 'react'

module.exports = React.createClass
    displayName: 'EmbedBlock'
    render: ->
        # TODO: render annotations, layout

        <div className='EmbedBlock'>
            <div className='_BlockContent'>
                {@props.block.content}
            </div>
        </div>

