###
Inside Base:
```
<ActivateClientModules modules=@props.client_modules />
```

On <Base>:

```
client_modules={
    onscroll: [{'.ArticleIndex__ ._Sidebar__': { top: 60, attrs: { 'data-fixed': true } }}]
    emailsubscribe: []
}
```

Inside modules to be selectively activated:

```
require('proof-sdk/client/client_modules').register('menu', activateMenu)
module.exports = activateMenu
```

###

_module_namespaces = {}
_activated_namespaces = {}
_unregistered_namespaces = {}

_activateModule = (namespace, module_name, module_args, is_deferred=false) ->
    if is_deferred
        console.info("Deferred activation of `#{ module_name }` in namespace `#{ namespace }`.")
    else
        console.info("Activating module `#{ module_name }` in namespace `#{ namespace }`.")
    if _module_namespaces[namespace][module_name]?
        if _module_namespaces[namespace][module_name].activate?
            _module_namespaces[namespace][module_name].activate(module_args...)
        else
            new _module_namespaces[namespace][module_name](module_args...)
        _activated_namespaces[namespace] ?= {}
        _activated_namespaces[namespace][module_name] = module_args
    else
        _unregistered_namespaces[namespace] ?= {}
        _unregistered_namespaces[namespace][module_name] = module_args
        console.warn("No module registered for `#{ module_name }` in namespace `#{ namespace }`, deferring.")

activateFn = (namespace='Marquee') ->
    window[namespace] ?= {}
    window[namespace] = activateModules: (modules={}) ->
            for module_name, module_args of modules
                _activateModule(namespace, module_name, module_args)

activateFn.register = (module_name, mod, namespace='Marquee') ->
    _module_namespaces[namespace] ?= {}
    _module_namespaces[namespace][module_name] = mod
    if _unregistered_namespaces[namespace]
        _args = _unregistered_namespaces[namespace][module_name]
        delete _unregistered_namespaces[namespace][module_name]
        _activateModule(namespace, module_name, _args, true)


module.exports = activateFn.activate = activateFn
