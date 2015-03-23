React = require 'react'
_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'Chartbeat'

    # Not required to ease use in development.
    propTypes:
        id      : React.PropTypes.string
        domain  : React.PropTypes.string

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