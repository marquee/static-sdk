// @flow

/*::
type LinkMatch = string | Map<any, string>
type LinkMap = Map<string, LinkMatch>
*/

class BuildState {
    /*::
    config: Object
    _config: ?Object
    _named_links: ?LinkMap
    _is_closed: boolean
    linkTo: Function
    fullLinkTo: Function
    _getFromConfig: Function
    _setFromConfig: Function
    BuildState: any
    */

    constructor () {

        this.__reset()

        this.linkTo = this.linkTo.bind(this)
        this.fullLinkTo = this.fullLinkTo.bind(this)
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


module.exports = new BuildState()
module.exports.BuildState = BuildState
