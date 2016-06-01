###
A template for rendering Facebook Instant Articles-compliant pages for Entries.

In addition to the API-generated fields, the Entry schema MUST have a
`cover_image` and `full_link`, and SHOULD have either a `fb_kicker` or
`meta_description`.
###

ImageBlock          = require './ImageBlock'
moment              = require 'moment'
React               = require 'react'
renderEntryContent  = require '../entry/renderEntryContent'
TextBlock           = require './TextBlock'



module.exports = React.createClass
    displayName: 'InstantEntry'
    propTypes:
        entry: React.PropTypes.shape(
                content             : React.PropTypes.array.isRequired
                cover_image         : React.PropTypes.object.isRequired
                fb_kicker           : React.PropTypes.kicker
                first_released_date : React.PropTypes.oneOfType(Date).isRequired
                full_link           : React.PropTypes.string.isRequired
                meta_description    : React.PropTypes.string
                modified_date       : React.PropTypes.oneOfType(Date).isRequired
                title               : React.PropTypes.string.isRequired
            ).isRequired
    render: ->

        cover_image = @props.entry.cover_image.w(1280)
        kicker = @props.entry.fb_kicker or @props.entry.meta_description
        # <!doctype html> -- added during emitFile
        <html lang='en' prefix='op: http://media.facebook.com/op#'>
            <head>
                <meta charSet='utf-8' />
                <link rel='canonical' href=@props.entry.full_link />
                <meta property='op:markup_version' content='v1.0' />
            </head>
            <body>
                <article>
                    <header>
                        <h1>{ @props.entry.title }</h1>

                        <time
                            className   = 'op-published'
                            dateTime    = @props.entry.first_released_date.toISOString()
                        >
                            {
                                moment(@props.entry.first_released_date).format(
                                    'MMMM Do, h:mm A'
                                )
                            }
                        </time>

                        <time
                            className   = 'op-modified'
                            dateTime    = @props.entry.modified_date.toISOString()
                        >
                            {
                                moment(@props.entry.modified_date).format(
                                    'MMMM Do, h:mm A'
                                )
                            }
                        </time>

                        <figure>
                            <img src=cover_image />
                        </figure>   

                        {
                            if kicker
                                <h3 className='op-kicker'>
                                    { kicker }
                                </h3>

                        }

                    </header>

                    {
                        renderEntryContent(
                            @props.entry.content,
                            plain: true
                            intercept: {
                                image: ImageBlock
                                text: TextBlock
                            }
                        )
                    }

                </article>
            </body>
        </html>
