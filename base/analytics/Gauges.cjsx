React = require 'react'
_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'Gauges'

    propTypes:
        id: React.PropTypes.string

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