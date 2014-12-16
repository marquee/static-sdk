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
request = require 'request'

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

        # Treat the old cover_content images as new ones.
        if name is 'cover_image'
            unless @_data.cover_content
                return null
            return new CDNImage(@_data.cover_content)

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




# Content API wrapper
# Wraps object in models that provide _date helpers, etc
class ContentAPI
    constructor: ({ token, host, project }) ->
        # The actual token permissions are not determined by the prefix, but
        # we can assume it reflects the permissions defined in the database.
        unless token.substring(0,2) is 'r0'
            TOKEN_PERM_MAP = {'rw': 'read-write', '0w': 'write-only'}
            throw new SDKError('tokens', "ContentAPI token MUST be read-only. Given token is labled #{ TOKEN_PERM_MAP[token.substring(0,2)] }.")
        @_token = token
        @_host = host

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
        SDKError.log("Making request to Content API: #{ colors.info(url) }, #{ opts.query }")
        request.get _options, (error, response, data) ->
            throw error if error
            # This API client is **read-only** and MUST only ever receive
            # a 200 from the API (or an error status), NEVER 201 or 204.
            unless response.statusCode is 200
                throw new SDKError('api', "Content API error: #{ response.statusCode }\n\n#{ data }", response.statusCode)
            if data.map?
                result = data.map (o) -> new Model(o.published_json)
            else
                result = new Model(data.published_json)
            opts.callback(result)

    # This is a good spot to make a generator or some sort of iterator instead,
    # since this holds all the objects in memory.
    filter: (query, cb) ->
        # if no callback, return queryset?
        LIMIT = 10
        query._limit ?= LIMIT
        query._offset ?= 0
        results = []
        num_last_batch = -1
        _makeRequest = =>
            if num_last_batch is 0
                cb(results)
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

    entries: (cb) ->
        @filter
            type: ENTRY
            is_released: true
            _sort: '-published_date'
        , (result) ->
            SDKError.log("Got #{ result.length } entries from API.")
            cb(result)

    packages: (cb) ->
        @filter
            type: PACKAGE
            is_released: true
            _sort: '-published_date'
        , (result) ->
            SDKError.log("Got #{ result.length } packages from API.")
            cb(result)

    posts: (cb) ->
        @filter
            type: POST
            _sort: '-start_date'
            is_public: true
        , (result) ->
            SDKError.log("Got #{ result.length } posts from API.")
            cb(result)

    channels: (cb) ->
        @filter
            type: CHANNEL
            _sort: 'created_date'
        , (result) ->
            SDKError.log("Got #{ result.length } channels from API.")
            cb(result)


module.exports = ContentAPI
