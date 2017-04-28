// @flow

// Separate from renderEntryContent to keep bundle sizes down
// if used client-side.

const ReactDOMServer = require('react-dom/server')
const renderEntryContent = require('./renderEntryContent')

function renderEntryContentToString (content/*: any */, options/*: any*/)/*: string */ {
    const result = renderEntryContent(content, options)
    if (null == result) {
        return ''
    }
    return result.map(ReactDOMServer.renderToStaticMarkup).join('')
}

module.exports = renderEntryContentToString