React = require 'react'

module.exports = React.createClass
    displayName: 'Asset'
    render: ->
        _render = =>
            full_path = "#{ global.ASSET_URL }#{ @props.path }"
            _ext = @props.path.split('.').pop()
            switch _ext
                when 'js', 'coffee'
                    if _ext is 'coffee'
                        full_path = full_path.replace('.coffee', '.js')
                    return <script src=full_path async=@props.async></script>

                when 'css', 'sass'
                    if _ext is 'sass'
                        full_path = full_path.replace('.sass', '.css')
                    return <link
                        rel     = 'stylesheet'
                        type    = 'text/css'
                        href    = full_path
                    />
                else
                    console.warn("Asset got unknown asset type (#{ _ext })")
                    return null

        return _render()