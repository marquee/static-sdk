###
This is a simple <Base> element with common components and properties. However,
most projects require substantial customization of the base markup. It is
recommended to use this as a starting point only, either as-is for early
development, or as a template to copy.
###

React   = require 'react'

{
    BuildInfo
    makeMetaTags
    Favicon
    Asset
    ElementQuery
    ActivateClientModules
    Namespace
} = require '.'

module.exports = React.createClass
    displayName: 'Base'

    propTypes:
        children        : React.PropTypes.arrayOf(React.PropTypes.element).isRequired
        canonical       : React.PropTypes.string
        className       : React.PropTypes.string
        client_modules  : React.PropTypes.objectOf(React.PropTypes.array)
        extra_body      : React.PropTypes.element
        extra_head      : React.PropTypes.element
        header          : React.PropTypes.element
        footer          : React.PropTypes.element
        meta            : React.PropTypes.objectOf(React.PropTypes.string)
        page            : React.PropTypes.string
        source_id       : React.PropTypes.string
        slug            : React.PropTypes.string
        title           : React.PropTypes.string

    getDefaultProps: -> {
        className: ''
        client_modules: {}
    }

    render: ->
        # Base client modules
        client_modules = {
            core_tracking   : [{
                source_id   : @props.source_id
                url         : if process.env.NODE_ENV is 'production' then 'http://events.marquee-cdn.net' else 'http://events-dev.marquee-cdn.net'
                publication : global.config.PUBLICATION_SHORT_NAME
            }]
        }

        # Page-specific client modules
        client_modules[k] = v for k,v of @props.client_modules

        <html>
            <head>
                <title>{ @props.title }</title>
                <meta charSet='utf-8' />
                <meta name='viewport' content='width=device-width, initial-scale=1, minimum-scale=1.0' />

                {
                    if @props.canonical
                        <link rel='canonical' href=@props.canonical />
                }

                {makeMetaTags(@props.meta)}

                <Asset path='style.sass' />
                <Favicon />

                {@props.extra_head}

            </head>
            <body
                className   = "Site__ -#{ @props.page } #{ @props.className }"
                data-slug   = @props.slug
                data-page   = @props.page
            >
                <div className='_SiteNav__'>
                    {@props.header}
                </div>

                <div className='_SiteContent__'>
                    {@props.children}
                </div>

                <div className='_SiteFooter__'>
                    {@props.footer}
                </div>

                <ElementQuery />
                <Namespace />
                <Asset path='script.coffee' />
                <ActivateClientModules modules=client_modules />

                {@props.extra_body}

                {
                    if process.env.NODE_ENV is 'production' and global.config.GOOGLE_ANALYTICS_ID
                        <GoogleAnalytics id=global.config.GOOGLE_ANALYTICS_ID />
                }

                <BuildInfo />
            </body>
        </html>
