React = require 'react'

Tags = React.createClass
    displayName: 'Tags'

    propTypes:
        tags: React.PropTypes.arrayOf(
                React.PropTypes.shape
                    slug: React.PropTypes.string
                    name: React.PropTypes.string
            )
    render: ->
        <div className='Tags'>
            {
                @props.tags?.map (t) ->
                    <span className='_Tag' data-slug=t.slug>{t.name}</span>
            }
        </div>