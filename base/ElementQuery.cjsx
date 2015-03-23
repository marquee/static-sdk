React = require 'react'

css = require 'css'


# Adapted from https://github.com/tysonmatanich/elementQuery
# Major difference is dropping IE <9 support, only using pixel values.
parseCSS = (css_source) ->
    query_data = {}
 
    addQueryDataValue = (selector, type, pair, number, value) ->
 
        selector = selector.trim()
 
        if selector
 
            unless number and value
                parts = /^([0-9]*.?[0-9]+)(px|em)$/.exec(pair)
                if parts?
                    number = Number(parts[1])
                    unless number.toString() is 'NaN'
                        value = parts[2]
 
            if value
                query_data[selector] ?= {}
                query_data[selector][type] ?= []
                query_data[selector][type].push(number)
 
    processSelector = (selector_text) ->
 
        if selector_text
 
            regex = /(\[(min\-width|max\-width|min\-height|max\-height)\~\=(\'|\")([0-9]*.?[0-9]+)(px|em)(\'|\")\])(\[(min\-width|max\-width|min\-height|max\-height)\~\=(\'|\")([0-9]*.?[0-9]+)(px|em)(\'|\")\])?/gi
 
            # Split out the full selectors separated by a comma ','
            selectors = selector_text.split(',')

            selectors.forEach (sel) ->
 
                selector = null
                prev_index = 0
                k = 0
                while k is 0 or result?
                    result = regex.exec(sel);
                    if result?
 
                        # result[2] = min-width|max-width|min-height|max-height
                        # result[4] = number
                        # result[5] = px|em
                        # result[7] = has another
 
                        # Ensure that it contains a valid numeric value to compare against
                        number = Number(result[4])
                        unless number.toString() is 'NaN'
 
                            unless selector?
                                # New set: update the current selector
                                selector = sel.substring(prev_index, result.index)
 
                                # Append second half of the selector
                                tail = sel.substring(result.index + result[1].length)
                                if tail.length > 0
                                     
                                    t = tail.indexOf(' ')
                                    if t isnt 0
                                        if t > 0
                                            # Take only the current part
                                            tail = tail.substring(0, t)
 
                                        # Remove any sibling element queries
                                        tail = tail.replace(/(\[(min\-width|max\-width|min\-height|max\-height)\~\=(\'|\")([0-9]*.?[0-9]+)(px|em)(\'|\")\])/gi, '')
                                        selector += tail
 
                            # Update the queryData object
                            addQueryDataValue(selector, result[2], result[4] + result[5], number, result[5])
 
                        if not result[7]
                            # Reached the end of the set
                            prev_index = result.index + result[1].length
                            selector = null
                        else
                            # Update result index to process next item in the set
                            regex.lastIndex = result.index + result[1].length
                    k++
 
    css.parse(css_source).stylesheet.rules.forEach (rule) ->
        rule.selectors?.forEach (selector) ->
            processSelector(selector)
 
    return query_data



UglifyJS = require 'uglify-js'
fs = require 'fs'
path = require 'path'
element_query_engine = fs.readFileSync(path.join(__dirname, '_element_query_engine.js')).toString()

module.exports = React.createClass
    displayName: 'ElementQuery'

    propTypes:
        styles: React.PropTypes.oneOfType([
            React.PropTypes.string
            React.PropTypes.arrayOf(React.PropTypes.string)
        ])


    getDefaultProps: -> {
        styles: ['style.sass']
    }

    render: ->
        unless @props.styles.map?
            stylesheets = [@props.styles]
        else
            stylesheets = @props.styles
        styles = stylesheets.map (stylesheet) ->
            file = path.join(global.build_info.asset_cache_directory, stylesheet)
            if file.split('.').pop() is 'sass'
                file = file.replace('.sass', '.css')
            return fs.readFileSync(file).toString()
        css_source = styles.join('')
        eq_script = """
                (function(){
                    var _query_data = #{ JSON.stringify(parseCSS(css_source), null, 4) };
                    #{ element_query_engine }
                })();
            """
        if process.env.NODE_ENV is 'production'
            eq_script = UglifyJS.minify(eq_script, fromString: true).code

        <script dangerouslySetInnerHTML={__html: eq_script} />