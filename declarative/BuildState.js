// @flow

/*::
type LinkMatch = string | Map<any, string>
type LinkMap = Map<string, LinkMatch>
type PathMap = Map<string, Array<any>>
*/

class BuildState {
    /*::
    config: Object
    _config: ?Object
    _named_links: ?LinkMap
    _named_paths: ?PathMap
    _is_closed: boolean
    linkTo: Function
    fullLinkTo: Function
    linkToPath: Function
    fullLinkToPath: Function
    _getFromConfig: Function
    _setFromConfig: Function
    BuildState: any
    */

    constructor () {

        this.__reset()

        this.linkTo = this.linkTo.bind(this)
        this.fullLinkTo = this.fullLinkTo.bind(this)
        this.linkToPath = this.linkToPath.bind(this)
        this.fullLinkToPath = this.fullLinkToPath.bind(this)
        this._getFromConfig = this._getFromConfig.bind(this)
        this._setFromConfig = this._setFromConfig.bind(this)
        // Need to keep this the same Proxy instance the whole time
        // so it can be imported using destructuring.
        this.config = new Proxy({}, {
            get: this._getFromConfig,
            set: this._setFromConfig,
        })
    }

    __reset () {
        this._config = null
        this._named_links = null
        this._named_paths = null
        this._is_closed = false
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

    __setPaths (new_paths/*: PathMap */) {
        if (null != this._named_paths) {
            throw new Error('Site description already parsed!')
        }
        this._named_paths = new_paths
    }

    __close () {
        if (this._is_closed) {
            throw new Error('BuildState already closed!')
        }
        this._is_closed = true
    }

    linkTo (name/*:string*/, key/*:?Object*/)/*: string*/ {
        if (this._is_closed) {
            throw new Error('BuildState closed! linkTo must be used before renders begin.')
        }
        if (null == this._named_links) {
            throw new Error('Site description not yet parsed!')
        }
        const name_links = this._named_links.get(name)
        if (null == name_links) {
            throw new Error(`Unknown link name: ${ name }`)
        }

        if ('string' === typeof name_links) {
            if (null != key) {
                throw new Error(`Cannot use key for ${ name } as routes are described`)
            } else {
                return name_links
            }
        }

        const matched_key = name_links.get(key)
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

    linkToPath (name/*:string*/, ...args/*:Array<any>*/)/*: string */ {
        if (this._is_closed) {
            throw new Error('BuildState closed! linkToPath must be used before renders begin.')
        }
        if (null == this._named_paths) {
            throw new Error('Site description not yet parsed!')
        }
        const name_path = this._named_paths.get(name)
        if (null == name_path) {
            throw new Error(`Unknown path name: ${ name }`)
        }

        const path_parts = name_path.map( (part,i) => {
            if ('function' === typeof part) {
                const arg = args.shift()
                const part_evaluated = part(arg)
                if (null == part_evaluated) {
                    throw new Error(`Path function to view '${ name }' returned null. Path functions must return a string.`)
                }
                return part_evaluated.toString()
            } else {
                return part.toString()
            }
        })
        if (path_parts.length > 1 && -1 === path_parts[path_parts.length - 1].indexOf('.')) {
            path_parts.push('/')
        }
        return path_parts.join('/').replace(/\/{2,}/g,'/')
    }

    fullLinkToPath (name/*:string*/, ...args/*:Array<any>*/)/*: string*/ {
        let link = this.linkToPath(name, ...args)
        if (null == this._config || null == this._config.HOST) {
            throw new Error('No HOST configured!')
        }
        const protocol = this._config.HTTPS ? 'https': 'http'
        link = `${ protocol }://${ this._config.HOST }${ link }`
        return link
    }

    _getFromConfig (target/*: Object */, name/*: string */) {
        if (null == this._config) {
            throw new Error('Site description not parsed yet! config properties cannot be accessed until after the main function begins execution.')
        }
        if (undefined === this._config[name]) {
            throw new Error(`Unknown config property: ${ name }`)
        }

        return this._config[name]
    }

    _setFromConfig (target/*: Object */, name/*: string */) {
        throw new Error(`config is not writable. Set "${ name }" in package.json.`)
    }

}

module.exports = BuildState