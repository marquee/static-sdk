React = require 'react'

DeferredStylesheet = React.createClass
    displayName: 'DeferredStylesheet'

    propTypes:
        href: React.PropTypes.string.isRequired

    render: ->
        <script dangerouslySetInnerHTML={
            __html: """
                (function(w){
                    function loadFont() {
                        var el = document.createElement('link');
                        el.href = '#{ @props.href }';
                        el.type = 'text/css';
                        el.rel = 'stylesheet';
                        document.body.appendChild(el);
                    };
                    var oldonload = window.onload;
                    window.onload = (typeof window.onload != 'function') ?
                      loadFont : function() { oldonload(); loadFont(); };
                })(window);
            """
        }></script>



module.exports = React.createClass
    displayName: 'GoogleFonts'

    propTypes:
        fonts   : React.PropTypes.objectOf(React.PropTypes.array).isRequired
        protocol: React.PropTypes.oneOf(['http', 'https']).isRequired
        text    : React.PropTypes.string
        defer   : React.PropTypes.bool
    getDefaultProps: -> {
        defer: false
        text: ''
        protocol: 'https'
    }

    render: ->
        fonts = []
        for name,weights of @props.fonts
            fonts.push "#{ name }:#{ weights.join(',') }"
        text = @props.text
        text = "&text=#{ text }" if text

        font_url = "#{ @props.protocol }://fonts.googleapis.com/css?family=#{ fonts.join('|') }#{ text }"

        if @props.defer
            return <DeferredStylesheet href=font_url />

        <link
            rel  = 'stylesheet'
            type = 'text/css'
            href = font_url
        />
