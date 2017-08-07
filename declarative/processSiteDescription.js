// @flow

const current_build         = require('../CURRENT-BUILD')
const extractLinks          = require('./extractLinks')
const extractPaths          = require('./extractPaths')
const expandDescription     = require('./expandDescription')
const flattenDescription    = require('./flattenDescription')
const gatherPropsInPlace    = require('./gatherPropsInPlace')
const makeDescriptionTree   = require('./makeDescriptionTree')
const React                 = require('react')
const SDKError              = require('../compiler/SDKError')
const { Enumerate, SitemapView } = require('./Site')


type Kwargs = {
    project_directory : string,
    project : any,
    config : Object,
    emitFile : Function
}

function processSiteDescription (kwargs : Kwargs) {
    const {
        project_directory,
        project,
        config,
        emitFile
    } = kwargs
    return function (site_description) {
        SDKError.log('Processing declarative site description...')

        // console.log('site_description', site_description)
        current_build.__setConfig(config)

        // Parse the given site description, dropping any subtrees marked
        // by a Skip.
        const description_tree = makeDescriptionTree(site_description)

        // Gather the path functions and extract a path map to each descriptor:
        // This is done before expansion because it's gathering unevaluated
        // path functions, and there is only one name per route possible.
        const named_paths = extractPaths(description_tree)
        console.log('named_paths', named_paths)
        current_build.__setPaths(named_paths)

        // Evaluate any Enumerate descriptors, creating new descriptors for
        // each child of the Enumerate. At this point any lazy iterables
        // used in an Enumerate will be evaluated.
        const expanded_description = expandDescription(description_tree)
        // console.log('expanded_description', expanded_description)
        // Evaluate links and extract a link map. This attaches an
        // `evaluated_path` to each descriptor in place.
        const named_links = extractLinks(expanded_description)
        // console.log(named_links)
        current_build.__setLinks(named_links)

        // The props functions of each descriptor are evaluated. At this point
        // any lazy querysets in mapDataToProps functions will be evaluated.
        gatherPropsInPlace(expanded_description)
        // The build state can no longer be modified, and information that
        // would inhibit parallelization can no longer be accessed.
        // (As of now this is only linkTo/fullLinkTo functions since they
        // require knowing the whole site structure and having the same
        // object instances available.)
        current_build.__close()

        // Flatten the tree to create an Array of every descriptor in the
        // site.
        // console.log(expanded_description)
        const all_descriptors = flattenDescription(expanded_description)
        // console.log(all_descriptors)
        SDKError.log(`${ all_descriptors.length } views found in declarative description.`)

        all_descriptors.forEach( descriptor => {
            // SitemapView is special and gets all_descriptors to do its thing.
            if (SitemapView === descriptor.type) {
                emitFile(
                    descriptor.evaluated_path,
                    SitemapView.makeEmit({ descriptor, config, all_descriptors }),
                    { 'Content-Type': SitemapView['Content-Type'] }
                )
            } else if (null != descriptor.evaluated_path && null != descriptor.type.makeEmit) {
                // <--- This would be a fantastic point to fire off emit
                //      action objects to something like a DynamoDB-based
                //      Lambda queue, if the `descriptor.type` had a
                //      `__filename` property exported.
                // console.log("descriptor", descriptor)
                emitFile(
                    descriptor.evaluated_path,
                    descriptor.type.makeEmit({ descriptor, config }),
                    {
                        'Content-Type'  : descriptor.type['Content-Type'],
                        fragment        : descriptor.props.fragment,
                        doctype         : null != descriptor.props.doctype ? descriptor.props.doctype : descriptor.type.doctype,
                    }
                )
            }
        })
    }
}


module.exports = processSiteDescription
