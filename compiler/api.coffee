ENTRY   = 'container'
PACKAGE = 'package'
POST    = 'post'
IMAGE   = 'image'
TEXT    = 'text'
EMBED   = 'embed'

util    = require 'util'
fs      = require 'fs'
request = require 'request'

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
            return @_data.cover_content?.content?['640']?.url

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





if fs.existsSync('.cache.json')
    CACHE = JSON.parse(fs.readFileSync('.cache.json'))
    for k,v of CACHE
        if v.map?
            CACHE[k] = v.map (o) -> new Model(o)
        else
            CACHE[k] = new Model(v)
else
    CACHE = {}

saveCache = ->
    fs.writeFileSync('.cache.json', JSON.stringify(CACHE))


# Content API wrapper
# Wraps object in models that provide _date helpers, etc
class ContentAPI
    constructor: ({ token, root, cache }) ->
        @_token = token
        @_root = root
        if cache
            @_cache = CACHE

    _sendRequest: (opts) ->
        if @_cache?[opts.url]
            util.log("Cached: #{ opts.url }")
            opts.callback(@_cache[opts.url])
            return

        headers =
            'Accept'        : 'application/json'
            'User-Agent'    : 'Marquee Static Compiler'
            'Authorization' : "Token #{ @_token }"
        opts.query ?= {}
        opts.query._include_published = true
        util.log("API: #{ opts.url }")
        req = rest.get(opts.url, query: opts.query, headers: headers)
        req.on 'error', (err) ->
            console.log err
        req.on 'success', (data) =>
            if data.map?
                result = data.map (o) -> new Model(o.published_json)
            else
                result = new Model(data.published_json)
            if @_cache?
                @_cache[opts.url] = result
                saveCache()
            opts.callback(result)

    filter: (query, cb) ->
        @_sendRequest
            url         : @_root
            query       : query
            callback    : cb

    entries: (cb) ->
        @filter
            type: ENTRY
            role__in: 'story,redirect,custom'
            is_released: true
            _sort: '-published_date'
        , cb
    packages: (cb) ->
        @filter
            type: PACKAGE
            is_released: true
            _sort: '-published_date'
        , cb
    posts: (cb) ->
        @filter
            type: POST
            _sort: '-start_date'
            is_public: true
        , cb

module.exports = ContentAPI