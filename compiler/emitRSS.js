module.exports = function emitRSS (emitFile) {
    return function _emitRSS (file_path, content, options={}) {
        options.content_type = 'application/rss+xml'
        if (null == options.metadata) {
            options.metadata = {}
        }
        options.metadata['Content-Type'] = options.content_type
        emitFile(file_path, content, options)
    }
}