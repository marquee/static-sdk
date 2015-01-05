ENTRY   = 'container'
PACKAGE = 'package'
POST    = 'post'
CHANNEL = 'channel'
IMAGE   = 'image'
TEXT    = 'text'
EMBED   = 'embed'

ENDPOINTS =
    container   : 'content/'
    package     : 'content/'
    post        : 'posts/'
    channel     : 'channels/'


fs      = require 'fs'
path    = require 'path'
request = require 'request'
W       = require 'when'

sdk_ua_string = require './sdk_ua_string'

SDKError = require './SDKError'
colors = SDKError.colors

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
            if _params.width? and _params.width > 640
                return @_obj.content['1280']?.url
            return @_obj.content['640']?.url

        url = @_url
        param_list = []
        for k,v of _params
            param_list.push("#{ k }=#{ v }") unless k is 'multiplier'
        return "#{ url }?#{ param_list.join('&') }"

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
    constructor: (array_of_results) ->
        @_items = array_of_results
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
    constructor: ({ token, host, project, use_cache, project_directory }) ->
        # The actual token permissions are not determined by the prefix, but
        # we can assume it reflects the permissions defined in the database.
        unless token.substring(0,2) is 'r0'
            TOKEN_PERM_MAP = {'rw': 'read-write', '0w': 'write-only'}
            throw new SDKError('tokens', "ContentAPI token MUST be read-only. Given token is labled #{ TOKEN_PERM_MAP[token.substring(0,2)] }.")
        @_token = token
        @_host = host
        @_project_directory = project_directory
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

    _sendRequest: (opts) ->

        opts.query ?= {}
        opts.query._include_published = true

        url = "http://#{ @_host }/#{ opts.url }"

        _options =
            json: true
            headers:
                'Accept'        : 'application/json'
                'User-Agent'    : @_ua
                'Authorization' : "Token #{ @_token }"
            url: url
            qs: opts.query
        SDKError.log("Making request to Content API: #{ colors.cyan(url) }, #{ JSON.stringify(opts.query) }")


        _returnData = (data) ->
            if data.map?
                result = data.map (o) -> new Model(o.published_json)
            else
                result = new Model(data.published_json)
            opts.callback(result)


        cache_key = url
        _query_keys = Object.keys(opts.query)
        _query_keys.sort()
        for _k in _query_keys
            cache_key += "#{ _k }=#{ opts.query[_k] }"
        if @_cache?[cache_key]
            SDKError.log(SDKError.colors.grey('Using response from API cache.'))
            _returnData(@_cache[cache_key])
        else
            request.get _options, (error, response, data) =>
                throw error if error
                # This API client is **read-only** and MUST only ever receive
                # a 200 from the API (or an error status), NEVER 201 or 204.
                unless response.statusCode is 200
                    throw new SDKError('api', "Content API error: #{ response.statusCode }\n\n#{ data }", response.statusCode)
                @_setCacheItem(cache_key, data)
                _returnData(data)

    _setUpCache: ->
        @_CACHE_FILE = path.join(@_project_directory, '.cache.json')
        try
            @_cache = JSON.parse(fs.readFileSync(@_CACHE_FILE).toString())
            SDKError.log(SDKError.colors.grey('Loaded API cache from file.'))
        catch e
            console.log e.message
            console.log e.stack
            SDKError.log(SDKError.colors.grey('No API cache file. Creating new cache...'))
            @_cache = {}

    _setCacheItem: (key, value) ->
        if @_cache?
            @_cache[key] = value
            fs.writeFileSync(@_CACHE_FILE, JSON.stringify(@_cache))
            SDKError.log(SDKError.colors.grey('Updated API cache file.'))


    # This is a good spot to make a generator or some sort of iterator instead,
    # since this holds all the objects in memory.
    filter: (query, cb) ->
        # if no callback, return queryset?

        deferred_result = W.defer()

        LIMIT = 10
        query._limit ?= LIMIT
        query._offset ?= 0
        results = []
        num_last_batch = -1
        _makeRequest = =>
            if num_last_batch is 0
                _results = new APIResults(results)

                deferred_result.resolve(_results)
                cb?(_results)
            else
                @_sendRequest
                    url         : ENDPOINTS[query.type]
                    query       : query
                    callback    : (_results) ->
                        results.push(_results...)
                        num_last_batch = _results.length
                        query._offset += LIMIT
                        _makeRequest()
        _makeRequest()
        return deferred_result.promise

    entries: (cb) ->
        @filter
            type: ENTRY
            is_released: true
            _sort: '-published_date'
        , (result) ->
            SDKError.log("Got #{ result.length } entries from API.")
            cb?(result)

    packages: (cb) ->
        @filter
            type: PACKAGE
            is_released: true
            _sort: '-published_date'
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

    ENTRY   : ENTRY
    PACKAGE : PACKAGE
    POST    : POST
    CHANNEL : CHANNEL
    IMAGE   : IMAGE
    TEXT    : TEXT
    EMBED   : EMBED

module.exports = ContentAPI
