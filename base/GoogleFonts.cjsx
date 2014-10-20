React = require 'react'

DeferredStylesheet = React.createClass
    displayName: 'DeferredStylesheet'
    render: ->
        <script dangerouslySetInnerHTML={
            __html: """
                (function(){
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
                })();
            """
        }></script>

module.exports = React.createClass
    displayName: 'GoogleFonts'
    getDefaultProps: -> {
        text: ''
    }
    render: ->
        fonts = []
        for name,weights of @props.fonts
            fonts.push "#{ name }:#{ weights.join(',') }"
        text = @props.text
        text = "&text=#{ text }" if text

        font_url = "http://fonts.googleapis.com/css?family=#{ fonts.join('|') }#{ text }"

        if @props.defer
            return <DeferredStylesheet href=font_url />

        <link
            rel  = 'stylesheet'
            type = 'text/css'
            href = font_url
        />