React = require 'react'

module.exports = React.createClass
    displayName: 'ActivateClientModules'

    propTypes:
        modules     : React.PropTypes.objectOf(React.PropTypes.array).isRequired
        namespace   : React.PropTypes.string

    getDefaultProps: -> {
        namespace: 'Marquee'
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

    statics:
        # Merges last-to-first for cleaner usage syntax, unlike normal
        # underscore.extend.
        merge: (module_deps...) ->
            modules = {}
            while module_deps.length > 0
                for k,v of module_deps.pop()
                    modules[k] = v
            return modules