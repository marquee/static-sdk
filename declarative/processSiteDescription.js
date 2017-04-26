const current_build         = require('../current-build')
const extractLinks          = require('./extractLinks')
const expandDescription     = require('./expandDescription')
const flattenDescription    = require('./flattenDescription')
const gatherPropsInPlace    = require('./gatherPropsInPlace')
const makeDescriptionTree   = require('./makeDescriptionTree')
const React                 = require('react')
const { Enumerate, Assets, Sitemap } = require('./Site')

function processSiteDescription (kwargs) {
    const {
        project_directory,
        project,
        config,
        emitFile
    } = kwargs
    return function (site_description) {
        const description_tree = makeDescriptionTree(site_description)
        const expanded_description = expandDescription(
            description_tree
        )
        // Evaluate links in place and extract a link map:
        const path_links = extractLinks(expanded_description)

        current_build.__setLinks(path_links)
        current_build.__setConfig(config)
        gatherPropsInPlace(expanded_description)
        current_build.__close()

        const all_descriptors = flattenDescription(expanded_description)

        all_descriptors.forEach( descriptor => {
            if (Sitemap === descriptor.type) {
                emitFile(
                    descriptor.evaluated_path,
                    Sitemap.makeEmit(descriptor, { all_descriptors, config }),
                    { 'Content-Type': Sitemap['Content-Type']}
                )
            } else if (null != descriptor.evaluated_path && null != descriptor.type.makeEmit) {
                emitFile(
                    descriptor.evaluated_path,
                    descriptor.type.makeEmit(descriptor)
                )
            }
        })
    }
}


module.exports = processSiteDescription 