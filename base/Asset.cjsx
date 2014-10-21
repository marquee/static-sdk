React = require 'react'
fs = require 'fs'
path = require 'path'

_render = (props) =>
    full_path = "#{ global.ASSET_URL }#{ props.path }"
    _ext = props.path.split('.').pop()
    switch _ext
        when 'js', 'coffee'
            if _ext is 'coffee'
                full_path = full_path.replace('.coffee', '.js')
            return <script src=full_path async=props.async></script>

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

_renderInline = (props) ->

    _path = path.join(global.build_info.project_directory, '.build', '.asset-cache', props.path)
    _ext = _path.split('.').pop()

    switch _ext
        when 'js', 'coffee'
            if _ext is 'coffee'
                _path = _path.replace('.coffee', '.js')
            file_content = fs.readFileSync(_path).toString()
            return <script dangerouslySetInnerHTML={__html: file_content} />

        when 'css', 'sass'
            if _ext is 'sass'
                full_path = full_path.replace('.sass', '.css')
            file_content = fs.readFileSync(_path).toString()
            return <style dangerouslySetInnerHTML={__html: file_content} />
        else
            console.warn("Asset got unknown asset type (#{ _ext })")
            return null



module.exports = React.createClass
    displayName: 'Asset'
    render: ->
        if @props.inline
            return _renderInline(@props)
        return _render(@props)