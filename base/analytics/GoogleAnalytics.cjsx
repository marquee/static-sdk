React = require 'react'
_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'GoogleAnalytics'

    propTypes:
        id: React.PropTypes.string

    render: ->
        return null unless @props.id
        _rawScript """
            (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
            (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
            })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

            ga('create', '#{ @props.id }', 'auto');
            ga('send', 'pageview');
        """
