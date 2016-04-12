fs      = require 'fs-extra'
path    = require 'path'
React   = require 'react'

_render = (props) =>
    full_path = "#{ global.ASSET_URL }#{ props.path }"
    _source_path = path.join(global.build_info.asset_cache_directory, props.path)
    _ext = props.path.split('.').pop()

    switch _ext
        when 'js', 'coffee', 'cjsx'
            if _ext in ['coffee', 'cjsx']
                full_path = full_path.replace(".#{ _ext }", '.js')
                _source_path = _source_path.replace(".#{ _ext }", '.js')
            output = <script src=full_path async=props.async></script>

        when 'css', 'sass'
            if _ext is 'sass'
                full_path = full_path.replace('.sass', '.css')
                _source_path = _source_path.replace('.sass', '.css')
            output = <link
                rel     = 'stylesheet'
                type    = 'text/css'
                href    = full_path
                media   = props.media
            />
        else
            console.warn("Asset got unknown asset type (#{ _ext })")
            return null

    # Ensure the asset is in the output directory.
    _dest_path = _source_path.replace(
            global.build_info.asset_cache_directory
            global.build_info.asset_dest_directory
        )
    unless fs.existsSync(_dest_path)
        fs.copySync(_source_path, _dest_path)

    return output

_renderInline = (props) ->

    _path = path.join(global.build_info.asset_cache_directory, props.path)
    _ext = _path.split('.').pop()

    switch _ext
        when 'js', 'coffee'
            if _ext is 'coffee'
                _path = _path.replace('.coffee', '.js')
            file_content = fs.readFileSync(_path).toString()
            return <script dangerouslySetInnerHTML={__html: file_content} />

        when 'css', 'sass'
            if _ext is 'sass'
                _path = _path.replace('.sass', '.css')
            file_content = fs.readFileSync(_path).toString()
            return <style dangerouslySetInnerHTML={__html: file_content} />
        else
            console.warn("Asset got unknown asset type (#{ _ext })")
            return null



module.exports = React.createClass
    displayName: 'Asset'
    propTypes:
        path    : React.PropTypes.string.isRequired
        async   : React.PropTypes.bool
        inline  : React.PropTypes.bool
        media   : React.PropTypes.string
    getDefaultPropts: ->
        media   : 'screen'
    render: ->
        if @props.inline
            return _renderInline(@props)
        return _render(@props)
