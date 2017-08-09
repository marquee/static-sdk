// @flow


const React = require('react')
const ReactDOMServer = require('react-dom/server')
const {provideAPIData, reallyMapDataToProps} = require("./utils.js")
const _ = require("lodash")

const HTMLView = props => null
HTMLView['Content-Type'] = 'text/html'
HTMLView.is_compressable = true

HTMLView.makeEmit = ({ descriptor }) => {
    let component      = descriptor.props.component;
    let gathered_props = descriptor.gathered_props;
    if(null != descriptor.props.data && null != descriptor.props.dataRequirements){
        const {data, dataRequirements} = descriptor.props
        component          = provideAPIData(dataRequirements)(component)
        const apiDataProps = reallyMapDataToProps(data, dataRequirements)
        gathered_props     = Object.assign({}, gathered_props, apiDataProps)
    }

    return React.createElement(component, gathered_props)
}

HTMLView.makeEmitFileArgs = (config, descriptor ) => {
    return [{
        evaluated_path  : descriptor.evaluated_path,
        viewElement     : descriptor.type.makeEmit( {descriptor, config} ),
        options         : {
            'Content-Type'  : descriptor.type['Content-Type'],
            fragment        : descriptor.props.fragment,
            doctype         : null != descriptor.props.doctype ? descriptor.props.doctype : descriptor.type.doctype,
        }
    }]
}

HTMLView.doctype = '<!doctype html>'
HTMLView.default_props = {
    fragment: false
}


const SitemapView = props => null
SitemapView['Content-Type'] = 'text/plain'
SitemapView.is_compressable = true
SitemapView.default_props = {
    path: 'sitemap.txt'
}

SitemapView.doctype = false
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
RSSView.doctype = '<?xml version="1.0"?>'

const Enumerate = props => null
Enumerate.Log = props => null

const Publication = props => null


/*
    <Enumerate
        items         = {{type: "entry"}}
        path          = {'/entries/:slug/'} // this must be a property on the underlying object. schemas yo!
        component     = {EntryDetail}
        data          = {data}
        globalContext = { {sections : {type : "topic", role : "section"} }
    />
*/


// const EnumerateItems = props => null
// EnumerateItems.makeHTMLViews = ({descriptor}) => {
//     const {items, data, component}
// }


const AssetPipeline = props => null

const Skip = props => null

AssetPipeline.Skip  = Skip
Enumerate.Skip      = Skip
HTMLView.Skip       = Skip
RSSView.Skip        = Skip
SitemapView.Skip    = Skip

Publication.Skip    = Skip

module.exports = {
    AssetPipeline,
    Enumerate,
    HTMLView,
    RSSView,
    SitemapView,
    Skip,
    Publication
}
