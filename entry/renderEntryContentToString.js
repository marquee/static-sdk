// Separate from renderEntryContent to keep bundle sizes down
// if used client-side.

const ReactDOMServer = require('react-dom/server')

function renderEntryContentToString (content, options) {
    const result = renderEntryContent(content, options)
    return result.map(ReactDOMServer.renderToStaticMarkup)
}

module.exports = renderEntryContentToString