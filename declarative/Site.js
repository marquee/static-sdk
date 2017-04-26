
const React = require('react')
const ReactDOMServer = require('react-dom/server')

const HTMLView = props => null
HTMLView['Content-Type'] = 'text/html'
HTMLView.is_compressable = true
HTMLView.renderOutput = (input) => '<!doctype>' + ReactDOMServer.renderToStaticMarkup(input)

const Sitemap = props => null
Sitemap['Content-Type'] = 'text/xml'
Sitemap.is_compressable = true
Sitemap.renderOutput = (input) => '<xml> Sitemap!'
Sitemap.default_props = {
    path: 'sitemap.xml'
}

const RSSView = props => null
RSSView['Content-Type'] = 'application/rss+xml'
RSSView.is_compressable = true
RSSView.renderOutput = (input) => '<xml> RSS!'

const Enumerate = props => null
Enumerate.Log = props => null

const Assets = props => null

const Skip = props => null

module.exports = {
    Assets,
    Enumerate,
    HTMLView,
    RSSView,
    Sitemap,
    Skip,
}