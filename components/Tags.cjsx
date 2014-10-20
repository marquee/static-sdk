React = require 'react'

Tags = React.createClass
    displayName: 'Tags'
    render: ->
        <div className='Tags'>
            {
                @props.tags?.map (t) ->
                    <span className='_Tag' data-slug=t.slug>{t.name}</span>
            }
        </div>