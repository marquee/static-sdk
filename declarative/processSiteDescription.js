const current_build         = require('../current-build')
const extractLinks          = require('./extractLinks')
const expandDescription     = require('./expandDescription')
const gatherPropsInPlace    = require('./gatherPropsInPlace')
const makeDescriptionTree   = require('./makeDescriptionTree')
const React                 = require('react')
const { Enumerate, Assets } = require('./Site')


// function renderNode (node, parent_path='', enumeration=null) {

//     if (node.type === Enumerate.Log) {
//         console.log(enumeration.item, 'AND PARENTS?')
//         return []
//     }

//     if (node.type === Assets) {
//         return []
//     }

//     if (node.type === Enumerate) {
//         if (null == node.children) {
//             throw new Error('Enumerate requires children views!')
//         }
//         let children = []
//         let _items = node.props.items
//         _items.forEach( (item, i) => {
//             node.children.forEach( c => {
//                 children.push(
//                     ...renderNode(c, parent_path, {
//                         item        : item,
//                         index       : i,
//                         next        : _items[i + 1],
//                         previous    : _items[i - 1],
//                         is_last     : false,
//                         is_first    : false,
//                         list        : _items,
//                     })
//                 )
//             })
//         })
//         return children
//     }

//     let output_path
//     let output_body

//     if (node.props.body) {
//         output_body = node.props.body
//     } else if (node.type.renderOutput) {
//         let component_props = node.props.props
//         if ('function' === typeof component_props) {
//             if (enumeration) {
//                 component_props = component_props(enumeration.item, enumeration.index, enumeration)
//             } else {
//                 component_props = component_props()
//             }
//         }
//         output_body = node.type.renderOutput(
//             React.createElement(
//                 node.props.component,
//                 component_props
//             )
//         )
//     }
    
//     output_path = node.props.path

//     if (typeof output_path === 'function') {
//         if (enumeration) {
//             output_path = output_path(enumeration.item, enumeration.index, enumeration)
//         } else {
//             output_path = output_path()
//         }
//     }
//     output_path = `${ parent_path }/${ output_path }`.replace(/\/+/g,'/')

//     let children = []
//     if (node.children) {
//         node.children.forEach( c => {
//             children.push(...renderNode(c, output_path))
//         })
//     }

//     const emit = { output_body, output_path }
//     return [emit, ...children]
// }




function processSiteDescription (kwargs) {
    const {
        project_directory,
        project,
        config,
        emitFile
    } = kwargs
    return function (site_description) {
        console.log('processSiteDescription 1', site_description)
        const description_tree = makeDescriptionTree(site_description)
        console.log('processSiteDescription 2', description_tree)
        const expanded_description = expandDescription(
            description_tree
        )
        console.log('processSiteDescription 3', expanded_description)
        const path_links = extractLinks(expanded_description)
        current_build.__setLinks(path_links)
        current_build.__setConfig(config)
        gatherPropsInPlace(expanded_description)
        current_build.__close()

    }
}


module.exports = processSiteDescription 