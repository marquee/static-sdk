// @flow

/*::
type LinkMatch = string | Map<any, string>
type LinkMap = Map<string, LinkMatch>
*/


function unsetConfig ()/*: Object*/ {
    return new Proxy({}, {
        get: (target, name) => {
            throw new Error('Site description not yet parsed')
        },
        set: () => {
            throw new Error('config is not writable')
        }
    })
}

function closedConfig ()/*: Object*/ {
    return new Proxy({}, {
        get: (target, name) => {
            throw new Error('BuildState closed! config must be accessed before renders begin.')
        },
        set: () => {
            throw new Error('config is not writable')
        }
    })
}

class BuildState {
    /*::
    config: ?any
    _config: ?{ HOST: string, HTTPS: ?boolean }
    _named_links: ?LinkMap
    _is_closed: boolean
    linkTo: Function
    fullLinkTo: Function
    BuildState: any
    */

    constructor () {

        this._config = unsetConfig()
        this._named_links = null
        this._is_closed = false

        // This is a workaround for flow checking Object.defineProperty using
        // a getter: https://github.com/facebook/flow/issues/285
        const _handlers/*: Object */ = {
            get             : this._getConfig.bind(this),
            enumerable      : true,
            configurable    : true,
            writeable       : false,
        }
        Object.defineProperty(this, 'config', _handlers)

        this.linkTo = this.linkTo.bind(this)
        this.fullLinkTo = this.fullLinkTo.bind(this)

    }

    _getConfig ()/*: Object */ {
        if (null == this._config) {
            throw new Error('Site description not yet parsed!')
        }
        if (this._is_closed) {
            throw new Error('BuildState closed! config must be accessed before renders begin.')
        }
        return this._config
    }

    __setConfig (new_config/*: Object */) {
        this._config = Object.freeze(new_config)
    }

    __setLinks (new_links/*: LinkMap */) {
        if (null != this._named_links) {
            throw new Error('Site description already parsed!')
        }
        this._named_links = new_links
    }

    __close () {
        if (this._is_closed) {
            throw new Error('BuildState already closed!')
        }
        this._is_closed = true
        this._config = closedConfig()
    }

    linkTo (name/*:string*/, key/*:?Object*/)/*: string*/ {
        if (this._is_closed) {
            throw new Error('BuildState closed! linkTo must be used before renders begin.')
        }
        if (null == this._named_links) {
            throw new Error('Site description not yet parsed!')
        }
        const name_paths = this._named_links.get(name)
        if (null == name_paths) {
            throw new Error(`Unknown link name: ${ name }`)
        }

        if ('string' === typeof name_paths) {
            if (null != key) {
                throw new Error(`Cannot use key for ${ name } as routes are described`)
            } else {
                return name_paths
            }
        }

        const matched_key = name_paths.get(key)
        if (null == matched_key) {
            throw new Error(`Key for link name ${ name } did not match any paths: ${ null != key ? key.toString() : 'null' }`)
        }
        return matched_key
    }

    fullLinkTo (name/*:string*/, key/*:?Object*/)/*: string*/ {
        let link = this.linkTo(name, key)
        if (null == this._config || null == this._config.HOST) {
            throw new Error('No HOST configured!')
        }
        const protocol = this._config.HTTPS ? 'https': 'http'
        link = `${ protocol }://${ this._config.HOST }${ link }`
        return link
    }

}


module.exports = new BuildState()
module.exports.BuildState = BuildState
