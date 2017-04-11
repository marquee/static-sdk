# Client Modules

Included in the Marquee Static SDK is a client-side module loading system that
provides a way for each kind of view to activate necessary scripts and pass
arguments on page load. It is not unlike the require.js method, but is
browserify-compatible, simpler to define modules for, and tailored to the
single bundle method of delivering the script to the browser.


## Inside client scripts

Inside a particular client script, the module exports an `activate` function
using the CommonJS style, and registers itself under a unique name.

```javascript
module.exports = {
    activate: (url_prefix, num_ctas) => {
        doSomething(num_ctas)
    }
}

require('proof-sdk/client/client_modules').register(
    'Entry', module.exports
)
```

The arguments passed to the `activate` method come from the activation system
and are specified by the view.

`module.exports` MAY also be a constructor. If it does not have an `activate`
method, it will be called with `new` and given the arguments.

```javascript
module.exports = Entry
require('proof-sdk/client/client_modules').register(
    'SomeModules', module.exports
)
```

(The module MAY register anything that is compatible with the activation
system, but registering `exports` is a handy convention so that a module can
be required by other modules and used directly instead, if necessary. Some
of the built-in utilities like `AsyncLoad` do this.)


## Inside the script entry point

A typical `script.js` entry point will look something like:

```javascript
# Buggyfill for iOS <8.0, Android <4.4
require('viewport-units-buggyfill').init()
require('fastclick')(document.body)

# Initialize the client_modules system.
require('proof-sdk/client/client_modules')()

# Modules activated by client modules.
require('proof-sdk/client/GalleryBlock')
require('proof-sdk/client/ImageBlock')
require('proof-sdk/client/ImageZoomer')
require('./ReadingProgress')
require('./ShareEntry')
require('./UAEvents')
require('./deferred_social')
require('./Entry')
require('./Header')
require('./NotFound')
require('./SearchApp')
```

The first two are used on all views and always activate as soon as the script
is parsed and evaluated. The `client_modules` require sets up the client-side
half of the Client Modules system. The remaining requires include those
modules in the output. They will evaluate along with the rest of the script,
but — depending on internal construction — will not do much until activated
by Client Modules as the view specifies.

Order SHOULD NOT matter, as the dependencies are handled by the `require`
calls and Browserify.

Note: the naming convention is to use CamelCase for modules that represent
potentially multiple objects in the view, such as `ShareEntry` widgets and
`ImageZoomer`, and snake_case for modules that only happen once in the view,
such as `deferred_social`.


#### Inside the view definition


Inside a view definition, the desired modules for that view can be specified,
along with arguments to be given to the modules’ activate methods or
constructors.


```jsx
<Base
    client_modules  = {{
        Entry               : [global.config.ROOT_PREFIX, props.num_ctas],
        ShareEntry          : [],
        entry_injections    : [props.num_to_inject],
        ImageZoomer         : [],
    }}
>
    …page content…
</Base>
```


## Inside `<Base>`

The above requires the `Base` element to insert module activation script into
the view when it renders. To do this, it uses the `<ActivateClientModules>`
element from `proof-sdk/base`.

Often there are modules that need to be used on all views, but need per-view
arguments. The `Base::render` method can be merge view-specific modules with
the globally used ones:

```jsx
# Base client modules
client_modules = {{
    AsyncLoad       : []
    UAEvents        : []
}}

# View-specific client modules
Object.assign(client_modules, props.client_modules)
```

and then include the activation element:

```jsx
<ActivateClientModules modules={ client_modules } />
```

The above renders the following JavaScript into the view:

```javascript
(function(w){
    w.addEventListener('load',function(){
        w['Marquee'].activateModules({
            "AsyncLoad": [],
            "UAEvents":[],
            "deferred_social":[],
            "entry":[
                "/",
                20,
            ],
            "ShareEntry":[],
            "entry_injections":[3],
            "ImageZoomer":[]
       });
    });
})(window);
```

This calls each of the modules loaded in the `script.coffee` entry point after
the `window` `load` event. Waiting for the load event prioritizes content.

Note: the `client_modules` activation system allows for deferred loading of
the modules using the `async` and `defer` attributes on `<script>` tags, so
the `<ActivateClientModules>` element may be placed anywhere.

