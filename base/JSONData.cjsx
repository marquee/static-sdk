React = require 'react'

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

        # Wrapped in a div since React only allows returning a single node.
        <div
            id          = @props.id
            className   = 'JSONData'
            style       = {display:'none'}
            aria-hidden = true
        >
            <script type='text/json' id="#{ @props.id }--DATA">
                {JSON.stringify(@props.children)}
            </script>
            <script dangerouslySetInnerHTML={__html: unescape_script}></script>
        </div>
