React = require 'react'

module.exports = React.createClass
    displayName: 'MarqueeBranding'
    getDefaultProps: -> {
            source      : global.config?.PUBLICATION_SHORT_NAME
            medium      : 'web'
            campaign    : 'sdk_site'
            content     : 'MarqueeBranding'
            logo_only   : false
        }
    render: ->
        link = 'http://marquee.by'
        if @props.source
            params = ['source','medium','campaign','content'].map (p) =>
                "utm_#{ p }=#{ @props[p] }"
            link += "?#{ params.join('&') }"

        <a
            className   = "MarqueeBranding #{ if @props.logo_only then '-logo_only' else ''}"
            href        = link
            title       = 'Marquee: easier, faster, more beautiful web publishing'
        >
            Made with Marquee
        </a>
