React = require 'react'

UglifyJS = require 'uglify-js'

module.exports = _rawScript = (script_str) ->
    if process.env.NODE_ENV is 'production'
        script_str = UglifyJS.minify(script_str, fromString: true).code
    <script dangerouslySetInnerHTML={
        __html: script_str
    } />