React = require 'react'

module.exports = React.createClass
    displayName: 'ActivateClientModules'
    getDefaultProps: -> {
        namespace: 'Marquee'
        modules: {}
    }
    render: ->
        return null if not @props.modules or Object.keys(@props.modules).length is 0

        _script = """
            (function(w){
                w.addEventListener('load',function(){
                    w['#{ @props.namespace }'].activateModules(#{ JSON.stringify(@props.modules) });
                });
            })(window);
        """
        <script dangerouslySetInnerHTML={
            __html: _script
        }/>
