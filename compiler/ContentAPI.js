/* DECAFFEINATED */
const { ENTRY, PACKAGE, POST, CHANNEL, IMAGE, TEXT, EMBED, TOPIC, LOCATION, PERSON } = require('./CONSTANTS');

const ENDPOINTS = {
    container   : 'releases/',
    package     : 'releases/',
    post        : 'posts/',
    channel     : 'channels/',
    person      : 'entities/',
    topic       : 'entities/',
    location    : 'entities/'
};


const fs = require('fs')
const path = require('path')
const request = require('request')
const W = require('when')
const url = require('url')
const sdk_ua_string = require('./sdk_ua_string')
const _ = require('lodash')
const SDKError = require('./SDKError')
const { colors } = SDKError;

const parseLinkHeader = require('parse-link-header')


class Model {
    constructor(source_data) {
        this._data = source_data;
        this._keys = [];
        this._configureProperties();
    }
        

    _configureProperties() {
        return (() => {
            let result = [];
            for (let k in this._data) {
                let v = this._data[k];
                let item;
                this._configureProp(k);
                if (k === 'cover_content') {
                    item = this._configureProp('cover_image');
                }
                result.push(item);
            }
            return result;
        })();
    }

    _configureProp(name) {
        this._keys.push(name);
        return Object.defineProperty(this, name, {
            get : () => this.get(name),
            set : new_val => this.set(name, new_val),
            enumerable : true,
            configurable : true
        }
        );
    }

    toJSON() { return this._data; }

    keys() { return this._keys; }

    get(name) {
        // Don't try to make the entry contents into Models
        if (['content', 'cover_content'].includes(name) && [ENTRY, IMAGE, TEXT,  EMBED].includes(this._data.type)) {
            return this._data[name];
        }

        switch (name.split('_').pop()) {
            case 'date':
                if (this._data[name]) {
                    return new Date(this._data[name]);
                }
                return null;
            // when 'content'
            //     val = @_data[name]
            //     unless val
            //         return null
            //     # Single Content Object
            //     if val.id
            //         if val.toJSON?
            //             return val
            //         return new Model(val)
            //     # List of Content Objects
            //     if val.map?
            //         return val.map (item) -> new Model(item)
            //     # Dictionary of Content Objects
            //     _val = {}
            //     for key,item of val
            //         _val[key] = new Model(item)
            //     return _val
            default:
                return this._data[name];
        }
    }

    set(name, value) {
        this._data[name] = value;
        return value;
    }

    copy() {
        let data_copy = JSON.parse(JSON.stringify(this._data));
        return new Model(data_copy);
    }
}


class APIResults {
    constructor(array_of_results, options) {
        if (options == null) { options = {}; }
        let _now = new Date();
        this._items = array_of_results.filter(function(item) {
            if (item.scheduled_release_date && !options.ignore_schedule) {
                return new Date(item.scheduled_release_date) <= _now;
            } else {
                return true;
            }
        });
        this.length = this._items.length;

        this._items.forEach((item, i) => {
            this[i] = item;
            if (item.id) { return this[item.id] = item; }
        });
    }


    aggregateBy() { return this.aggregatedBy(...arguments); }
    aggregatedBy(property) {
        let result = {};
        this._items.forEach(function(item) {
            if (item[property] != null) {
                if (result[item[property]] == null) { result[item[property]] = []; }
                return result[item[property]].push(item);
            }
        });
        return result;
    }

    forEach() { return this._items.forEach(...arguments); }
    map() { return this._items.map(...arguments); }
    slice() { return this._items.slice(...arguments); }
    shift() {
        let _res = this._items.shift();
        this.length = this._items.length;
        return _res;
    }
    pop() {
        let _res = this._items.pop();
        this.length = this._items.length;
        return _res;
    }
    copy() { return new APIResults([...Array.from(this._items)]); }
    sortedBy(key) {
        let descending;
        if (key[0] === '-') {
            key = key.slice(1);
            descending = true;
        } else {
            descending = false;
        }
        let sorted_list = _.sortBy(this.copy(), key);
        if (descending) {
            sorted_list.reverse();
        }
        return new APIResults(sorted_list);
    }

    paginated(page_size, linkerFn) {
        if (page_size == null) { page_size = 10; }
        if (linkerFn == null) { linkerFn = APIResults.defaultLinker; }
        let pages = _.chunk(this._items, page_size).map(function(chunk, i) {
            let page_number = i + 1;
            return {
                items   : chunk,
                number  : page_number,
                link    : linkerFn(page_number)
            };});
        pages.forEach(function(page, i) {
            page.next = pages[i + 1];
            return page.previous = pages[i - 1];});
        return pages;
    }
}


APIResults.defaultLinker = function(n) {
    if (n) {
        if (n > 1) {
            return `/${ n }/`;
        }
        return '/';
    }
    return null;
};




// Content API wrapper
// Wraps object in models that provide _date helpers, etc
class ContentAPI {
    static initClass() {
    
        this.prototype.ENTRY        = ENTRY;
        this.prototype.PACKAGE      = PACKAGE;
        this.prototype.POST         = POST;
        this.prototype.CHANNEL      = CHANNEL;
        this.prototype.IMAGE        = IMAGE;
        this.prototype.TEXT         = TEXT;
        this.prototype.EMBED        = EMBED;
        this.prototype.PERSON       = PERSON;
        this.prototype.LOCATION     = LOCATION;
        this.prototype.TOPIC        = TOPIC;
    }
    constructor({ token, host, project, config, use_cache, project_directory, ignore_schedule, api_page_size, smart_cache, stale_after }) {
        // The actual token permissions are not determined by the prefix, but
        // we can assume it reflects the permissions defined in the database.
        if (token.substring(0,2) !== 'r0') {
            let TOKEN_PERM_MAP = {'rw': 'read-write', '0w': 'write-only'};
            throw new SDKError('tokens', `ContentAPI token MUST be read-only. Given token is labled ${ TOKEN_PERM_MAP[token.substring(0,2)] }.`);
        }
        this._token = token;
        this._host = host;
        this._project_directory = project_directory;
        this._ignore_schedule = ignore_schedule;
        this._api_page_size = api_page_size;

        this._smart_cache = smart_cache;
        this._stale_after = stale_after;

        if (use_cache) {
            this._setUpCache();
        }

        if (smart_cache) {
            this._setUpSmartCache();
        }

        // If being used within the context of a publication, assemble a User
        // Agent string that includes the publication information. Otherwise,
        // use the default SDK User Agent string. An assembled string looks
        // something like:
        //
        //    shortname/1.0.0 proof-sdk/0.8.0 (+http://shortname.proof.press)
        //
        if (project) {
            this._ua = config.PUBLICATION_SHORT_NAME;
            if (project.version) {
                this._ua += `/${ project.version }`;
            }
            this._ua += ` ${ sdk_ua_string }`;
            this._ua += ` (+http://${ config.HOST })`;
        } else {
            this._ua = sdk_ua_string;
        }
    }

    _nameCacheFile(key) {
        return path.join(this._CACHE_DIRECTORY, key.replace(/[^\w]+/g,'-'));
    }

    _sendRequest(opts) {

        let _url, headers, next_url;
        if (opts.query == null) { opts.query = {}; }

        if (url.parse(opts.url).protocol) {
            _url = opts.url;
        } else {
            _url = `http://${ this._host }/${ opts.url }`;
        }

        let _options = {
            json: true,
            headers: {
                'Accept'        : 'application/json',
                'User-Agent'    : this._ua,
                'Authorization' : `Token ${ this._token }`
            },
            url: _url,
            qs: opts.query
        };
        SDKError.log(`Making request to Content API: ${ colors.cyan(_url) }, ${ JSON.stringify(opts.query) }`);


        let _returnData = function(data, next_url) {
            let result;
            if (next_url == null) { next_url = null; }
            if (data.map != null) {
                result = data.map(function(o) {
                    if (o.published_json) {
                        return new Model(o.published_json);
                    }
                    return new Model(o);
                });
            } else {
                if (data.published_json) {
                    result = new Model(data.published_json);
                } else {
                    result = new Model(data);
                }
            }
            return opts.callback(result, next_url);
        };


        let cache_key = `${ this._token }--${ _url }`;
        let _query_keys = Object.keys(opts.query);
        _query_keys.sort();
        for (let _k of Array.from(_query_keys)) {
            cache_key += `${ _k }=${ opts.query[_k] }`;
        }

        let _fetchData = () => {
            return request.get(_options, (error, response, data) => {
                if (error) {
                    console.error(_url);
                    throw error;
                }
                // This API client is **read-only** and MUST only ever receive
                // a 200 from the API (or an error status), NEVER 201 or 204.
                if (response.statusCode !== 200) {
                    throw new SDKError('api', `Content API error: ${ response.statusCode }\n\n${ data }`, response.statusCode);
                }
                ({ headers } = response);
                this._setCacheItem(cache_key, { data, headers });
                next_url = __guard__(__guard__(parseLinkHeader(headers.link), x1 => x1.next), x => x.url);
                return _returnData(data, next_url);
            });
        };

        if (this._CACHE_DIRECTORY) {
            return fs.readFile(this._nameCacheFile(cache_key), function(err, data) {
                if (err != null) {
                    _fetchData();
                    return;
                }
                SDKError.log(SDKError.colors.grey(`Using response from API cache (${ data.length } bytes).`));
                ({ data, headers } = JSON.parse(data.toString()));
                if (!data || !headers) {
                    throw new SDKError('api', "Invalid API cache: clear the cache (`rm -r .api-cache`) and try again.");
                }
                next_url = __guard__(__guard__(parseLinkHeader(headers.link), x1 => x1.next), x => x.url);
                return _returnData(data, next_url);
            });
        } else {
            return _fetchData();
        }
    }

    _setUpCache() {
        this._CACHE_DIRECTORY = path.join(this._project_directory, '.api-cache');
        if (!fs.existsSync(this._CACHE_DIRECTORY)) {
            SDKError.log(SDKError.colors.grey('No API cache. Creating new cache...'));
            return fs.mkdirSync(this._CACHE_DIRECTORY);
        }
    }

    _setUpSmartCache() {
        this._SMART_CACHE_DIRECTORY = path.join(this._project_directory, '.smart-cache');
        if (!fs.existsSync(this._SMART_CACHE_DIRECTORY)) {
            SDKError.log(SDKError.colors.grey('No API smart cache. Creating new smart cache...'));
            return fs.mkdirSync(this._SMART_CACHE_DIRECTORY);
        }
    }

    _setCacheItem(key, value) {
        if (this._CACHE_DIRECTORY != null) {
            let cache_file = this._nameCacheFile(key);
            value = JSON.stringify(value);
            fs.writeFileSync(cache_file, value);
            return SDKError.log(SDKError.colors.grey(`Updated API cache file (${ value.length } bytes).`));
        }
    }


    _getSmartCacheItems(type) {
        let cache_file = path.join(this._SMART_CACHE_DIRECTORY, `${ type }.json`);
        if (fs.existsSync(cache_file)) {
            let cache_data;
            try {
                cache_data = JSON.parse(fs.readFileSync(cache_file));
            } catch (e) {
                SDKError.warn(`Unable to read smart-cache file: ${ cache_file }, ignoring!`);
            }
            if (cache_data != null) {
                let { data, date } = cache_data;
                return [
                    data.map(item => new Model(item)),
                    new Date(date)
                ];
            }
        }
        return [[], null];
    }

    _setSmartCacheItems(type, items, date) {
        let cache_file = path.join(this._SMART_CACHE_DIRECTORY, `${ type }.json`);
        SDKError.log(`smart cache, saving ${ items.length } ${ type } items...`);
        return fs.writeFileSync(cache_file, JSON.stringify({data: items, date}));
    }

    _filterReleasesWithSmartCache(query, cb) {
        let _now = new Date();
        let deferred_result = W.defer();

        let [cached_items, last_fetched_at] = Array.from(this._getSmartCacheItems(query.type));

        SDKError.log(`smart cache, ${ query.type }: ${ cached_items.length } cached items`);

        // Other types don't have the `type` property, so this needs to be
        // removed from the query for the filtering to work correctly.
        let _url = ENDPOINTS[query.type];
        if (![ENTRY, PACKAGE, PERSON, TOPIC, LOCATION].includes(query.type)) {
            delete query.type;
        }

        let results_set = {};

        let max_modified_date = null;
        cached_items.forEach(function(item) {
            if ((item.modified_date && (item.modified_date > max_modified_date)) || !max_modified_date) {
                max_modified_date = item.modified_date;
            }
            return results_set[item.id] = item;
        });

        SDKError.log(`smart cache, ${ query.type }: max modified_date ${ max_modified_date }`);

        if (max_modified_date) {
            if (((_now - last_fetched_at) < (this._stale_after * 1000 * 60 * 60)) || !last_fetched_at) {
                query.modified_date__gte = max_modified_date.toISOString().replace(/Z$/,'');
            } else {
                cached_items = [];
                results_set = {};
            }
        }

        let results = [];
        let next_url = _url;
        var _makeRequest = () => {
            if (!next_url) {
                let _num_new = results.length;
                for (let item of Array.from(results)) { results_set[item.id] = item; }
                results = ((() => {
                    let result = [];
                    for (let k in results_set) {
                        let v = results_set[k];
                        result.push(v);
                    }
                    return result;
                })());
                SDKError.log(`smart cache, ${ query.type }: ${ _num_new } modified, ${ results.length } total`);
                this._setSmartCacheItems(query.type, results, _now);
                let _results = new APIResults(results, {ignore_schedule: this._ignore_schedule});
                deferred_result.resolve(_results);
                return (typeof cb === 'function' ? cb(_results) : undefined);
            } else {
                return this._sendRequest({
                    url         : next_url,
                    query,
                    callback(_results, _next_url) {
                        next_url = _next_url;
                        results.push(...Array.from(_results || []));
                        return _makeRequest();
                    }
                });
            }
        };
        _makeRequest();
        return deferred_result.promise;
    }

    filterReleases(query, cb) {
        if (this._smart_cache) {
            return this._filterReleasesWithSmartCache(query, cb);
        }


        let deferred_result = W.defer();

        // Other types don't have the `type` property, so this needs to be
        // removed from the query for the filtering to work correctly.
        let _url = ENDPOINTS[query.type];
        if (![ENTRY, PACKAGE, PERSON, TOPIC, LOCATION].includes(query.type)) {
            delete query.type;
        }

        let results = [];
        let next_url = _url;
        var _makeRequest = () => {
            if (!next_url) {
                let _results = new APIResults(results, {ignore_schedule: this._ignore_schedule});

                deferred_result.resolve(_results);
                return (typeof cb === 'function' ? cb(_results) : undefined);
            } else {
                return this._sendRequest({
                    url         : next_url,
                    query,
                    callback(_results, _next_url) {
                        next_url = _next_url;
                        results.push(...Array.from(_results || []));
                        return _makeRequest();
                    }
                });
            }
        };
        _makeRequest();
        return deferred_result.promise;
    }

    // This is a good spot to make a generator or some sort of iterator instead,
    // since this holds all the objects in memory.
    filter(query, cb) {
        // if no callback, return queryset?

        let deferred_result = W.defer();

        // Other types don't have the `type` property, so this needs to be
        // removed from the query for the filtering to work correctly.
        let _url = ENDPOINTS[query.type];
        if (![ENTRY, PACKAGE, PERSON, TOPIC, LOCATION].includes(query.type)) {
            delete query.type;
        }

        let LIMIT = 10;
        if (query._limit == null) { query._limit = LIMIT; }
        if (query._offset == null) { query._offset = 0; }
        let results = [];
        let num_last_batch = -1;
        var _makeRequest = () => {
            if (num_last_batch === 0) {
                let _results = new APIResults(results, {ignore_schedule: this._ignore_schedule});

                deferred_result.resolve(_results);
                return (typeof cb === 'function' ? cb(_results) : undefined);
            } else {
                return this._sendRequest({
                    url         : _url,
                    query,
                    callback(_results) {
                        results.push(...Array.from(_results || []));
                        num_last_batch = _results.length;
                        query._offset += LIMIT;
                        return _makeRequest();
                    }
                });
            }
        };
        _makeRequest();
        return deferred_result.promise;
    }

    entries(cb) {
        return this.filterReleases({
            type: ENTRY,
            page_size: this._api_page_size
        }
        , function(result) {
            SDKError.log(`Got ${ result.length } entries from API.`);
            return (typeof cb === 'function' ? cb(result) : undefined);
        });
    }

    packages(cb) {
        return this.filterReleases({
            type: PACKAGE,
            page_size: this._api_page_size
        }
        , function(result) {
            SDKError.log(`Got ${ result.length } packages from API.`);
            return (typeof cb === 'function' ? cb(result) : undefined);
        });
    }

    posts(cb) {
        return this.filter({
            type: POST,
            _sort: '-start_date',
            is_public: true
        }
        , function(result) {
            SDKError.log(`Got ${ result.length } posts from API.`);
            return (typeof cb === 'function' ? cb(result) : undefined);
        });
    }

    channels(cb) {
        return this.filter({
            type: CHANNEL,
            _sort: 'created_date'
        }
        , function(result) {
            SDKError.log(`Got ${ result.length } channels from API.`);
            return (typeof cb === 'function' ? cb(result) : undefined);
        });
    }

    people(cb) {
        return this.filterReleases({
            type: PERSON,
            page_size: this._api_page_size
        }
        , function(result) {
            SDKError.log(`Got ${ result.length } people from API.`);
            return (typeof cb === 'function' ? cb(result) : undefined);
        });
    }

    locations(cb) {
        return this.filterReleases({
            type: LOCATION,
            page_size: this._api_page_size
        }
        , function(result) {
            SDKError.log(`Got ${ result.length } locations from API.`);
            return (typeof cb === 'function' ? cb(result) : undefined);
        });
    }

    topics(cb) {
        return this.filterReleases({
            type: TOPIC,
            page_size: this._api_page_size
        }
        , function(result) {
            SDKError.log(`Got ${ result.length } topics from API.`);
            return (typeof cb === 'function' ? cb(result) : undefined);
        });
    }

    loadData() {
        return new Promise((function(resolve, reject) {
            return Promise.all([
                this.entries(), this.packages(), this.people(), this.locations(), this.topics()
            ]).then(normalizeContentData).then(resolve)
            .catch(reject);
        }.bind(this)));
    }
}
ContentAPI.initClass();

var normalizeContentData = function(all_collections) {
    let object_index = new Map();
    all_collections.forEach(collection =>
        collection.forEach(model => object_index.set(model.id, model))
    );

    let _getFromIndex = function(obj_or_id) {
        if (!obj_or_id) {
            return;
        }
        if (obj_or_id.id) {
            return object_index.get(obj_or_id.id);
        }
        return object_index.get(obj_or_id);
    };

    all_collections.forEach(collection =>
        collection.forEach(model =>
            model.keys().forEach(function(key) {
                if (!model[key]) {
                    return;
                }
                let _type = key.split('_').pop();

                if (['content', 'entities', 'entity'].includes(_type) && !((model.type === ENTRY) && (key === 'content'))) {
                    if (Array.isArray(model[key])) {
                        return model[key] = model[key].map(_getFromIndex);
                    } else if (typeof model[key] === 'object') {
                        if (model[key].id) {
                            if (object_index[model[key].id]) {
                                return model[key] = object_index.get(model[key].id);
                            } else {
                                return console.warn('UNKNOWN?', key, model[key]);
                            }
                        } else {
                            return Object.keys(model[key]).forEach(k => model[key][k] = _getFromIndex(model[key][k]));
                        }
                    } else if ((typeof model[key] === 'string') && object_index.get(model[key])) {
                        return model[key] = object_index.get(model[key]);
                    }
                }
            })
        )
    );

    let [entries, packages, people, locations, topics] = Array.from(all_collections);
    return { entries, packages, people, locations, topics };
};


module.exports = ContentAPI;

module.exports.Model = Model
module.exports.APIResults = APIResults

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}