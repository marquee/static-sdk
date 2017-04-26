
const React = require('react')
const ReactDOMServer = require('react-dom/server')

const HTMLView = props => null
HTMLView['Content-Type'] = 'text/html'
HTMLView.is_compressable = true
HTMLView.makeEmit = descriptor => React.createElement(descriptor.props.component, descriptor.gathered_props)

const Sitemap = props => null
Sitemap['Content-Type'] = 'text/plain'
Sitemap.is_compressable = true
Sitemap.default_props = {
    path: 'sitemap.txt'
}
const r = React.createElement
const ONE_MONTH = 1000 * 60 * 60 * 24 * 30
Sitemap.makeEmit = (descriptor, { all_descriptors, config }) => {

    const links = new Set()
    all_descriptors.forEach( d => {
        if (null != d.evaluated_path) {
            links.add(( config.HTTPS ? 'https' : 'http' ) + '://' + config.HOST + d.evaluated_path)
        }
    })

    return [...links.values()].join('\n')
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