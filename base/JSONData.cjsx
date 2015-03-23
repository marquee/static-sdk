React = require 'react'

fs          = require 'fs'
path        = require 'path'
UglifyJS    = require 'uglify-js'

module.exports = React.createClass
    displayName: 'JSONData'
    render: ->
        unescape_script = """
            (function(){
                var entity_map = {
                  '&amp;'   : '&',
                  '&lt;'    : '<',
                  '&gt;'    : '>',
                  '&quot;'  : '"',
                  '&#x27;'  : "'"
                };
                var exp = new RegExp('(&amp;|&lt;|&gt;|&quot;|&#x27;)', 'g');
                function _unescape(data_str) {
                    if(data_str == null) {
                        return '';
                    }
                    var data = data_str.replace(exp, function(match){
                        return entity_map[match];
                    });
                    return data;
                };
                if(!window.initial_data) {
                    window.initial_data = {};
                }
                window.initial_data['#{ @props.id }'] = JSON.parse(_unescape(document.getElementById('#{ @props.id }--DATA').innerHTML));
            })();
        """

        if process.env.NODE_ENV is 'production'
            unescape_script = UglifyJS.minify(unescape_script, fromString: true).code

        if @props.file
            # Parse it to ensure it is valid JSON data.
            json_data = JSON.parse(
                    fs.readFileSync(
                        path.join(
                            global.build_info.project_directory,
                            @props.file
                        )
                    ).toString()
                )
        else
            json_data = @props.children

        if process.env.NODE_ENV is 'production'
            json_data = JSON.stringify(json_data)
        else
            json_data = JSON.stringify(json_data, null, 4)

        # Wrapped in a div since React only allows returning a single node.
        <div
            id          = @props.id
            className   = 'JSONData'
            style       = {display:'none'}
            aria-hidden = true
        >
            <script type='text/json' id="#{ @props.id }--DATA">
                {json_data}
            </script>
            <script dangerouslySetInnerHTML={__html: unescape_script}></script>
        </div>
