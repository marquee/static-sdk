module.exports = (emitFile) ->
    _emitRSS = (file_path, content, options={}) ->
        options.content_type = 'application/rss+xml'
        options.metadata ?= {}
        options.metadata['Content-Type'] = options.content_type
        emitFile(file_path, content, options)
    return _emitRSS