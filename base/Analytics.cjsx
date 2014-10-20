React = require 'react'


UglifyJS = require 'uglify-js'


_rawScript = (script_str) ->
    <script dangerouslySetInnerHTML={
        __html: UglifyJS.minify(script_str, fromString: true).code
    } />


module.exports.GoogleAnalytics = React.createClass
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


module.exports.ChartbeatStart = React.createClass
    displayName: 'ChartbeatStart'
    render: ->
        _rawScript """
            window._sf_startpt=(new Date()).getTime();
        """


module.exports.Chartbeat = React.createClass
    displayName: 'Chartbeat'
    render: ->
        return null unless @props.id and @props.domain
        _rawScript """
            (function() {
                window._sf_async_config = { uid: "#{ @props.id }", domain: "#{ @props.domain }", useCanonical: true };
                function loadChartbeat() {
                    window._sf_endpt = (new Date()).getTime();
                    var el = document.createElement('script');
                    el.src = '//static.chartbeat.com/js/chartbeat.js';
                    document.body.appendChild(el);
                };
                var oldonload = window.onload;
                window.onload = (typeof window.onload != 'function') ?
                  loadChartbeat : function() { oldonload(); loadChartbeat(); };
            })();
        """

 
module.exports.Gauges = React.createClass
    displayName: 'Gauges'
    render: ->
        return null unless @props.id
        _rawScript """
            (function() {
                window._gauges = window._gauges || [];
                var t   = document.createElement('script');
                t.async = true;
                t.id    = 'gauges-tracker';
                t.setAttribute('data-site-id', '#{ @props.id }');
                t.src = '//secure.gaug.es/track.js';
                var s = document.getElementsByTagName('script')[0];
                s.parentNode.insertBefore(t, s);
            })();
        """