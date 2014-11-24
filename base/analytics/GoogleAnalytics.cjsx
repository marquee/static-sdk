React = require 'react'
_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'GoogleAnalytics'
    render: ->
        return null unless @props.id
        _rawScript """
            (function() {
                var _gaq = window._gaq || [];
                _gaq.push(['_setAccount', '#{ @props.id }']);
                _gaq.push(['_trackPageview']);
                window._gaq = _gaq;
                var ga = document.createElement('script');
                ga.type = 'text/javascript';
                ga.async = true;
                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();
        """
