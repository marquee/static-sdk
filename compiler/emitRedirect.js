
module.exports = function emitRedirect (emitFile) {
    return function _emitRedirect (file_path, target_url) {

        // Tells S3 to redirect to a different URL instead of serving the
        // object at `file_path`.
        const metadata = {
            'website-redirect-location': target_url,
            'Content-Type': 'text/html',
        }

        // In case they end up on the page directly anyway. (Can happen under
        // certain built-in hosts for S3 static hosting, and for local testing.)
        const file_content = `
            <!doctype html><html><head>
            <meta http-equiv="refresh" content="0;url=${ target_url }">
            </head><body></body></html>
        `
        emitFile(file_path, file_content, {
            content_type: 'text/html',
            metadata: metadata,
        })

    }
}