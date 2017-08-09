const {
    AssetPipeline,
    Enumerate,
    HTMLView,
    RSSView,
    SitemapView,
    Skip,
    Publication,
    EnumerateViews
} = require('./declarative/Site')

const {
    requiresAPIData
} = require("./declarative/utils.js")


module.exports = {
    AssetPipeline,
    Enumerate,
    EnumerateViews,
    HTMLView,
    RSSView,
    SitemapView,
    Skip,
    Publication,
    requiresAPIData,
    entry: require('./entry'),
    renderEntryContent: require('./entry/renderEntryContent'),
    ContentImage: require('./components/ContentImage'),
}
