
const React = require('react')
const ReactDOMServer = require('react-dom/server')

const HTMLView = props => null
HTMLView['Content-Type'] = 'text/html'
HTMLView.is_compressable = true
HTMLView.makeEmit = ({ descriptor }) => (
    React.createElement(descriptor.props.component, descriptor.gathered_props)
)

const SitemapView = props => null
SitemapView['Content-Type'] = 'text/plain'
SitemapView.is_compressable = true
SitemapView.default_props = {
    path: 'sitemap.txt'
}
const r = React.createElement
const ONE_MONTH = 1000 * 60 * 60 * 24 * 30
SitemapView.makeEmit = ({ descriptor, all_descriptors, config }) => {

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
RSSView.makeEmit = ({ descriptor }) => (
    React.createElement(descriptor.props.component, descriptor.gathered_props)
)

const Enumerate = props => null
Enumerate.Log = props => null

const AssetPipeline = props => null

const Skip = props => null

AssetPipeline.Skip  = Skip
Enumerate.Skip      = Skip
HTMLView.Skip       = Skip
RSSView.Skip        = Skip
SitemapView.Skip    = Skip

module.exports = {
    AssetPipeline,
    Enumerate,
    HTMLView,
    RSSView,
    SitemapView,
    Skip,
}