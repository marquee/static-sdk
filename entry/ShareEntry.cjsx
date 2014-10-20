React = require 'react'

# The share widget is designed to be progressively enhanced. It works without
# client-side script, using CSS hover and regular links.

SERVICE_PROPER_NAMES =
    facebook    : 'Facebook'
    twitter     : 'Twitter'
    googleplus  : 'Google+'
    pinterest   : 'Pinterest'
    appdotnet   : 'App.net'
    linkedin    : 'LinkedIn'

buildLinkFor = (entry, service) ->
    link    = encodeURIComponent(entry.full_link)
    cover   = encodeURIComponent(entry.cover_image)
    title   = encodeURIComponent(entry.title)
    summary = encodeURIComponent(entry.summary)

    switch service
        # https://developer.linkedin.com/documents/share-linkedin
        when 'linkedin'
            return "http://www.linkedin.com/shareArticle?mini=true&url=#{link}&title=#{title}&summary=#{summary}"
        when 'facebook'
            return "http://www.facebook.com/sharer/sharer.php?s=100&p[url]=#{link}&p[images][0]=#{cover}&p[title]=#{title}&p[summary]=#{summary}"
        when 'twitter'
            return "http://twitter.com/home?status=#{title}%20%E2%80%93%20#{link}"
        when 'googleplus'
            return "https://plus.google.com/share?url=#{link}"
        when 'pinterest'
            return "http://www.pinterest.com/pin/create/button/?url=#{link}&media=#{cover}&description=#{title}"
        when 'appdotnet'
            return "https://alpha.app.net/intent/post/?text=#{title}&url=#{link}"
        when 'email'
            body = """
                #{ entry.title }
                by #{ entry.byline }

                #{ entry.summary }

                #{ entry.full_link }
            """
            body = encodeURIComponent(body)
            return "mailto:?subject=#{ title }&body=#{ body }"

    return null

module.exports = React.createClass
    displayName: 'ShareEntry'
    render: ->
        <div className='ShareEntry'>
            <span className='_Label'>Share</span>
            <div
                className = '_Services'
            >
                {
                    @props.services.map (service) =>
                        _popup = service isnt 'email'
                        <a
                            href        = {buildLinkFor(@props.entry, service)}
                            className   = "_ShareLink -#{ service }"
                            target      = {if _popup then '_blank' else null}
                            tabIndex    = 0
                            key         = service
                            aria-label  = "Share #{ @props.entry.title } on #{ service }"
                            data-popup  = _popup
                        >
                            {SERVICE_PROPER_NAMES[service]}
                        </a>
                }
            </div>
        </div>