ENTRY       = 'container'
PACKAGE     = 'package'
POST        = 'post'
CHANNEL     = 'channel'
IMAGE       = 'image'
TEXT        = 'text'
EMBED       = 'embed'
TOPIC       = 'topic'
LOCATION    = 'location'
PERSON      = 'person'

ENDPOINTS =
    container   : 'releases/'
    package     : 'releases/'
    post        : 'posts/'
    channel     : 'channels/'
    person      : 'entities/'
    topic       : 'entities/'
    location    : 'entities/'


fs      = require 'fs'
path    = require 'path'
request = require 'request'
W       = require 'when'
url     = require 'url'
sdk_ua_string = require './sdk_ua_string'

SDKError = require './SDKError'
colors = SDKError.colors

parseLinkHeader = require 'parse-link-header'

# Wraps the CDN image URLs for easier manipulation of CDN resizing parameters.
# Also abstracts the legacy image format.
# entry.cover_image.width(300).height(200).crop('fit')
# entry.cover_image.w(300).x2()
class CDNImage
    constructor: (image, params={}) ->
        @_original = image
        if typeof image is 'object'
            @_obj = image
        else
            @_url = image
        @_params = params

    width: (w) ->
        return @copy(width: w)

    height: (h) ->
        return @copy(height: h)

    w: -> @width(arguments...)
    h: -> @height(arguments...)

    x2: ->
        @_params.multiplier = 2
        return this

    x3: ->
        @_params.multiplier = 3
        return this

    copy: (new_params={}) ->
        _params = {}
        for k,v of @_params
            _params[k] = v
        for k,v of new_params
            _params[k] = v
        return new CDNImage(@_original, _params)

    toString: ->

        _params = JSON.parse(JSON.stringify(@_params))

        # Apply the retina multiplier.
        if _params.multiplier
            _params.width = _params.width * _params.multiplier if _params.width
            _params.height = _params.height * _params.multiplier if _params.height
            delete _params.multiplier

        # Handle legacy images, approximating the resize effect.
        if @_obj
            unless @_obj.content?
                console.warn("Legacy image object without content: #{ @_obj.id }")
                return null
            if _params.width? and _params.width > 640
                return @_obj.content['1280']?.url
            return @_obj.content['640']?.url

        param_list = []
        for k,v of _params
            param_list.push("#{ k }=#{ v }") unless k is 'multiplier'
        return "#{ @_url }?#{ param_list.join('&') }"

class Model
    constructor: (source_data) ->
        @_data = source_data
        @_configureProperties()

    _configureProperties: ->
        for k,v of @_data
            @_configureProp(k)
            if k is 'cover_content'
                @_configureProp('cover_image')

    _configureProp: (name) ->
        Object.defineProperty this, name,
            get : => @get(name)
            set : (new_val) => @set(name, new_val)
            enumerable : true
            configurable : true

    toJSON: -> @_data

    get: (name) ->
        # Don't try to make the entry contents into Models
        if name in ['content', 'cover_content'] and @_data.type in [ENTRY, IMAGE, TEXT,  EMBED]
            return @_data[name]

        if name is 'cover_image'
            unless @_data.cover_image
                return null
            return new CDNImage(@_data.cover_image)

        switch name.split('_').pop()
            when 'date'
                if @_data[name]
                    return new Date(@_data[name])
                return null
            # when 'content'
            #     val = @_data[name]
            #     unless val
            #         return null
            #     # Single Content Object
            #     if val.id
            #         if val.toJSON?
            #             return val
            #         return new Model(val)
            #     # List of Content Objects
            #     if val.map?
            #         return val.map (item) -> new Model(item)
            #     # Dictionary of Content Objects
            #     _val = {}
            #     for key,item of val
            #         _val[key] = new Model(item)
            #     return _val
            else
                return @_data[name]

    set: (name, value) ->
        @_data[name] = value
        return value

    copy: ->
        data_copy = JSON.parse(JSON.stringify(@_data))
        return new Model(data_copy)


class APIResults
    constructor: (array_of_results, options={}) ->
        _now = new Date()
        @_items = array_of_results.filter (item) ->
            if item.scheduled_release_date and not options.ignore_schedule
                return new Date(item.scheduled_release_date) <= _now
            else
                return true
        @length = @_items.length

        @_items.forEach (item, i) =>
            @[i] = item
            @[item.id] = item if item.id


    aggregateBy: (property) ->
        result = {}
        @_items.forEach (item) ->
            if item[property]?
                result[item[property]] ?= []
                result[item[property]].push(item)
        return result

    forEach: -> @_items.forEach(arguments...)
    map: -> @_items.map(arguments...)
    slice: -> @_items.slice(arguments...)
    shift: ->
        _res = @_items.shift()
        @length = @_items.length
        return _res
    pop: ->
        _res = @_items.pop()
        @length = @_items.length
        return _res





# Content API wrapper
# Wraps object in models that provide _date helpers, etc
class ContentAPI
    constructor: ({ token, host, project, use_cache, project_directory, ignore_schedule }) ->
        # The actual token permissions are not determined by the prefix, but
        # we can assume it reflects the permissions defined in the database.
        unless token.substring(0,2) is 'r0'
            TOKEN_PERM_MAP = {'rw': 'read-write', '0w': 'write-only'}
            throw new SDKError('tokens', "ContentAPI token MUST be read-only. Given token is labled #{ TOKEN_PERM_MAP[token.substring(0,2)] }.")
        @_token = token
        @_host = host
        @_project_directory = project_directory
        @_ignore_schedule = ignore_schedule
        if use_cache
            @_setUpCache()

        # If being used within the context of a publication, assemble a User
        # Agent string that includes the publication information. Otherwise,
        # use the default SDK User Agent string. An assembled string looks
        # something like:
        #
        #    shortname/1.0.0 marquee-static-sdk/0.10.0 (+http://shortname.marquee.pub)
        #
        if project
            @_ua = project.name
            if project.version
                @_ua += "/#{ project.version }"
            @_ua += " #{ sdk_ua_string }"
            @_ua += " (+http://#{ project.marquee.HOST })"
        else
            @_ua = sdk_ua_string

    _nameCacheFile: (key) ->
        path.join(@_CACHE_DIRECTORY, key.replace(/[^\w]+/g,'-'))

    _sendRequest: (opts) ->

        opts.query ?= {}

        if url.parse(opts.url).protocol
            _url = opts.url
        else
            _url = "http://#{ @_host }/#{ opts.url }"

        _options =
            json: true
            headers:
                'Accept'        : 'application/json'
                'User-Agent'    : @_ua
                'Authorization' : "Token #{ @_token }"
            url: _url
            qs: opts.query
        SDKError.log("Making request to Content API: #{ colors.cyan(_url) }, #{ JSON.stringify(opts.query) }")


        _returnData = (data, next_url=null) ->
            if data.map?
                result = data.map (o) ->
                    if o.published_json
                        return new Model(o.published_json)
                    return new Model(o)
            else
                if data.published_json
                    result = new Model(data.published_json)
                else
                    result = new Model(data)
            opts.callback(result, next_url)


        cache_key = "#{ @_token }--#{ _url }"
        _query_keys = Object.keys(opts.query)
        _query_keys.sort()
        for _k in _query_keys
            cache_key += "#{ _k }=#{ opts.query[_k] }"

        _fetchData = =>
            request.get _options, (error, response, data) =>
                if error
                    console.error(_url)
                    throw error
                # This API client is **read-only** and MUST only ever receive
                # a 200 from the API (or an error status), NEVER 201 or 204.
                unless response.statusCode is 200
                    throw new SDKError('api', "Content API error: #{ response.statusCode }\n\n#{ data }", response.statusCode)
                { headers } = response
                @_setCacheItem(cache_key, { data, headers })
                next_url = parseLinkHeader(headers.link)?.next?.url
                _returnData(data, next_url)

        if @_CACHE_DIRECTORY
            fs.readFile @_nameCacheFile(cache_key), (err, data) ->
                if err?
                    _fetchData()
                    return
                SDKError.log(SDKError.colors.grey("Using response from API cache (#{ data.length } bytes)."))
                { data, headers } = JSON.parse(data.toString())
                unless data and headers
                    throw new SDKError('api', "Invalid API cache: clear the cache (`rm -r .api-cache`) and try again.")
                next_url = parseLinkHeader(headers.link)?.next?.url
                _returnData(data, next_url)
        else
            _fetchData()

    _setUpCache: ->
        @_CACHE_DIRECTORY = path.join(@_project_directory, '.api-cache')
        unless fs.existsSync(@_CACHE_DIRECTORY)
            SDKError.log(SDKError.colors.grey('No API cache. Creating new cache...'))
            fs.mkdirSync(@_CACHE_DIRECTORY)

    _setCacheItem: (key, value) ->
        if @_CACHE_DIRECTORY?
            cache_file = @_nameCacheFile(key)
            value = JSON.stringify(value)
            fs.writeFileSync(cache_file, value)
            SDKError.log(SDKError.colors.grey("Updated API cache file (#{ value.length } bytes)."))

    filterReleases: (query, cb) ->
        deferred_result = W.defer()

        # Other types don't have the `type` property, so this needs to be
        # removed from the query for the filtering to work correctly.
        _url = ENDPOINTS[query.type]
        unless query.type in [ENTRY, PACKAGE, PERSON, TOPIC, LOCATION]
            delete query.type

        results = []
        next_url = _url
        _makeRequest = =>
            unless next_url
                _results = new APIResults(results, ignore_schedule: @_ignore_schedule)

                deferred_result.resolve(_results)
                cb?(_results)
            else
                @_sendRequest
                    url         : next_url
                    query       : query
                    callback    : (_results, _next_url) ->
                        next_url = _next_url
                        results.push(_results...)
                        _makeRequest()
        _makeRequest()
        return deferred_result.promise

    # This is a good spot to make a generator or some sort of iterator instead,
    # since this holds all the objects in memory.
    filter: (query, cb) ->
        # if no callback, return queryset?

        deferred_result = W.defer()

        # Other types don't have the `type` property, so this needs to be
        # removed from the query for the filtering to work correctly.
        _url = ENDPOINTS[query.type]
        unless query.type in [ENTRY, PACKAGE, PERSON, TOPIC, LOCATION]
            delete query.type

        LIMIT = 10
        query._limit ?= LIMIT
        query._offset ?= 0
        results = []
        num_last_batch = -1
        _makeRequest = =>
            if num_last_batch is 0
                _results = new APIResults(results, ignore_schedule: @_ignore_schedule)

                deferred_result.resolve(_results)
                cb?(_results)
            else
                @_sendRequest
                    url         : _url
                    query       : query
                    callback    : (_results) ->
                        results.push(_results...)
                        num_last_batch = _results.length
                        query._offset += LIMIT
                        _makeRequest()
        _makeRequest()
        return deferred_result.promise

    entries: (cb) ->
        @filterReleases
            type: ENTRY
        , (result) ->
            SDKError.log("Got #{ result.length } entries from API.")
            cb?(result)

    packages: (cb) ->
        @filterReleases
            type: PACKAGE
        , (result) ->
            SDKError.log("Got #{ result.length } packages from API.")
            cb?(result)

    posts: (cb) ->
        @filter
            type: POST
            _sort: '-start_date'
            is_public: true
        , (result) ->
            SDKError.log("Got #{ result.length } posts from API.")
            cb?(result)

    channels: (cb) ->
        @filter
            type: CHANNEL
            _sort: 'created_date'
        , (result) ->
            SDKError.log("Got #{ result.length } channels from API.")
            cb?(result)

    people: (cb) ->
        @filterReleases
            type: PERSON
        , (result) ->
            SDKError.log("Got #{ result.length } people from API.")
            cb?(result)

    locations: (cb) ->
        @filterReleases
            type: LOCATION
        , (result) ->
            SDKError.log("Got #{ result.length } locations from API.")
            cb?(result)

    topics: (cb) ->
        @filterReleases
            type: TOPIC
        , (result) ->
            SDKError.log("Got #{ result.length } topics from API.")
            cb?(result)

    ENTRY       : ENTRY
    PACKAGE     : PACKAGE
    POST        : POST
    CHANNEL     : CHANNEL
    IMAGE       : IMAGE
    TEXT        : TEXT
    EMBED       : EMBED
    PERSON      : PERSON
    LOCATION    : LOCATION
    TOPIC       : TOPIC

module.exports              = ContentAPI
module.exports.CDNImage     = CDNImage
module.exports.Model        = Model
module.exports.APIResults   = APIResults
