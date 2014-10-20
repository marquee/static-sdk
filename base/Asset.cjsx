React = require 'react'

path = require 'path'
fs = require 'fs'

CoffeeScript    = require 'coffee-script'
Sass            = require 'node-sass'
UglifyJS        = require 'uglify-js'
sqwish          = require 'sqwish'
autoprefixer    = require 'autoprefixer-core'

compileSass = (project_root, source_path) ->
    compiled = Sass.renderSync
        file: source_path
        includePaths: [project_root]
    return compiled

compileCoffee = (project_root, source_path) ->
    source = fs.readFileSync(source_path).toString()
    compiled = CoffeeScript.compile(source)
    # TODO: browserify
    return compiled

minifyScript = (script_str) -> UglifyJS.minify(script_str, fromString: true).code
prefixAndMinifyCSS = (css_str) ->
    css_str = autoprefixer.process(css_str).css
    return sqwish.minify(css_str)

_inline_asset_cache = {}

module.exports = React.createClass
    displayName: 'Asset'
    render: ->
        # Reset the asset cache
        if Object.keys(_inline_asset_cache).length > 5
            _inline_asset_cache = {}
        _inline_asset_cache[global.ASSET_URL] ?= {}

        _render = =>
            full_path = "#{ global.ASSET_URL }#{ @props.path }"
            _ext = @props.path.split('.').pop()
            switch _ext
                when 'js', 'coffee'
                    if @props.inline
                        source_path = path.join(global.PROJECT_ROOT, 'assets', @props.path)
                        if _ext is 'coffee'
                            asset_content = compileCoffee(global.PROJECT_ROOT, source_path)
                        else
                            asset_content = fs.readFileSync(source_path).toString()
                        asset_content = minifyScript(asset_content)
                        return <script dangerouslySetInnerHTML={
                                __html: asset_content
                            }></script>
                    if _ext is 'coffee'
                        full_path = full_path.replace('.coffee', '.js')
                    return <script src=full_path async=@props.async></script>

                when 'css', 'sass'
                    if @props.inline
                        source_path = path.join(global.PROJECT_ROOT, 'assets', @props.path)
                        if _ext is 'sass'
                            asset_content = compileSass(global.PROJECT_ROOT, source_path)
                        else
                            asset_content = fs.readFileSync(source_path).toString()
                        asset_content = prefixAndMinifyCSS(asset_content)
                        return <style dangerouslySetInnerHTML={
                                __html: asset_content
                            }></style>
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

        if @props.inline and _inline_asset_cache[global.ASSET_URL][@props.path]?
            return _inline_asset_cache[global.ASSET_URL][@props.path]

        output = _render()
        if @props.inline
            _inline_asset_cache[global.ASSET_URL][@props.path] = output
        return output