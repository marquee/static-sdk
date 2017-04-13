React = require 'react'
ReactDOMServer = require 'react-dom/server'

SDKError    = require './SDKError'
colors      = SDKError.colors

path        = require 'path'
fs          = require 'fs'
mime        = require 'mime'
crypto      = require 'crypto'

# Create a singular cache of the emits so that the development server always
# uses the same emit cache as each build. Otherwise it won't see changes.
emit_cache = {}

circularJSONStringify = (obj) ->
    cache = new Set()
    result = JSON.stringify obj, (key, value) ->
        if typeof value is 'object' and value isnt null
            if cache.has(value)
                # Circular reference found, discard key
                return
            cache.add(value)
        return value
    return result



getContentChecksum = (content) ->
    hashed_content = crypto.createHash('md5').update(
        content
    ).digest('hex')
    return "#{ global.build_info.commit }/#{ global.build_info.asset_hash }/raw_content=#{ hashed_content }"

getReactChecksum = (element) ->
    hashed_props = crypto.createHash('md5').update(
        circularJSONStringify(element.props)
    ).digest('hex')
    return "#{ global.build_info.commit }/#{ global.build_info.asset_hash }/#{ element.type.name or element.type.displayName or 'React.Component' }-props=#{ hashed_props }"

getCacheKey = (filepath) ->
    crypto.createHash('md5').update(filepath).digest('hex')


module.exports = ({ project_directory, project, config, writeFile, exportMetadata, defer_emits, build_cache }) ->

    _getReactCache = (key) ->
        p = path.join(build_cache_directory, key)
        cached = null
        if fs.existsSync(p)
            try
                cached = JSON.parse(fs.readFileSync(p).toString())
            catch e
                console.error(e)
                cached = null
        return cached

    _setReactCache = (key, to_cache) ->
        p = path.join(build_cache_directory, key)
        to_cache = JSON.stringify(to_cache)
        fs.writeFileSync(p, to_cache)

    # Require the project's copy of React so that the below validation and
    # rendering will work. Fails silently since React is not required at this
    # point. (For some reason, different copies of React can't validate each
    # other's components?)
    project_react_path = path.join(project_directory, 'node_modules', 'react')

    _processContent = (file_content, options={}) ->
        switch typeof file_content
            when 'string'
                return [null, file_content]

            when 'object'
                if React.isValidElement(file_content)
                    output_content = ReactDOMServer.renderToStaticMarkup(file_content)
                    output_content = "<!doctype html>#{ output_content }" unless options.fragment
                    return ['text/html', output_content]

                # It looks like a React component but somehow React wasn't
                # installed locally for the project.
                if file_content._store?.props?
                    SDKError.log('project.react', "Did you mean to render a React component? React MUST be installed locally for the project in order to pass `emitFile` a React component.")

                # Try turning the data into JSON
                try
                    output_content = JSON.stringify(file_content)
                catch e
                    throw new SDKError('emitFile.json', e)
                return ['application/json', output_content]
            else
                throw new SDKError('emitFile', "emitFile got unknown type of content: #{ typeof file_content }")

    _processPath = (file_path) ->
        # Turn paths that end in a directory into `path/index.html` for clean URLs
        if file_path.indexOf('.') is -1
            return "#{ file_path }/index.html".replace(/\/{2,}/g,'/')
        return file_path

    files_emitted = []

    if defer_emits
        # Reuse the existing cache object so the development server can see
        # the changes, but be sure to flush it for consistency.
        files_emitted_indexed = emit_cache
        Object.keys(files_emitted_indexed).forEach (k) -> files_emitted_indexed[k] = null
    else
        files_emitted_indexed = {}

    # The actual function given to the compiler for generating files.
    emitFile = (file_path, file_content, options={}) ->

        # Using variable-defined paths can easily cause undefined to be used.
        unless file_path?
            throw new SDKError('emitFile.path', 'emitFile got an undefined path')

        # Allow for scoping the entire site under a /path/
        if config.ROOT_PREFIX
            file_path = path.join(config.ROOT_PREFIX, file_path)

        output_path     = _processPath(file_path)
        output_type     = null
        output_content  = null

        _doProcess = ->
            _output_cache = null
            _checksum = null

            if build_cache?
                if React.isValidElement(file_content)
                    _new_checksum = getReactChecksum(file_content)
                else if typeof file_content is 'string'
                    _new_checksum = getContentChecksum(file_content)

            if build_cache and output_path and _new_checksum and _new_checksum is build_cache[output_path]
                SDKError.log(colors.grey("Skipping unchanged build-cache version of #{ output_path }@#{ _new_checksum }"))
                _output_type = null
                _output_content = null
            else
                [_output_type, _output_content] = _processContent(file_content, options)
                if build_cache and _new_checksum
                    SDKError.log(colors.grey("Adding to build-cache: #{ output_path }@#{ _new_checksum }"))
                    build_cache[output_path] = _new_checksum

            output_content_to_render = file_content
            output_type = _output_type
            output_content = _output_content

            if options.content_type
                output_type = options.content_type

            # If _processContent didn't specify a content type, guess based on
            # the output path.
            unless output_type
                output_type = mime.lookup(output_path)

            unless defer_emits or not output_content
                SDKError.log("Saving #{ colors.green(output_path) } #{ colors.grey('(' + output_content.length + ' bytes, ' + output_type + ')') }")
                writeFile
                    path        : output_path
                    content     : output_content
                    type        : output_type
            return [output_type, output_content]

        unless defer_emits
            _doProcess()

        if defer_emits or output_content
            files_emitted.push(output_path)
            if files_emitted_indexed[output_path]
                SDKError.warn("File emitted multiple times: #{ output_path }")
            else
                files_emitted_indexed[output_path] = {
                    path: output_path,
                    # Avoid hanging on to the _doProcess function to prevent
                    # a memory leak.
                    render: if defer_emits then _doProcess else null,
                    type: output_type,
                }
            output_content = null

            exportMetadata(file_path, options.metadata) if options.metadata

    emitFile.files_emitted = files_emitted
    files_emitted._indexed = files_emitted_indexed
    emitFile.files_emitted_indexed = files_emitted_indexed

    return emitFile

