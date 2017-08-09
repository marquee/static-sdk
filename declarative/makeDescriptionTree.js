// @flow

const React = require('react')
const { Skip, Publication, Enumerate, EnumerateViews } = require('./Site')
const {reallyMapDataToProps} = require("./utils.js")
/*::
type DescriptorNode = {
    parent   : ?DescriptorNode,
    type     : Object,
    props    : Object,
    children : Array<DescriptorNode>,
}
*/

function makeDescriptionTree (node/*: React.Element<*> */, parent/*: ?DescriptorNode */, apiData )/*: ?DescriptorNode */ {
    if (null == node.type) {
        let _message = 'Undefined view descriptor type specified. It probably is not exported or imported properly.'
        if (null != node.props.name) {
            _message += ` Check the view descriptor for ${ node.props.name }`
        } else if (null == parent) {
            _message += ' Check the top-level view descriptors.'
        } else if (null != parent.props.name) {
            _message += ` Check the children of ${ parent.props.name }`
        } else {
            _message += ` Check the children of ${ parent.type.name }`
        }
        throw new Error(_message)
    }
    if (Skip === node.type) {
        return null
    }



    const props = {}
    if (null != node.type.default_props) {
        Object.assign(props, node.type.default_props)
    }
    Object.assign(props, {apiData : apiData})
    let children = []
    if (null != node.props) {

        children = React.Children.toArray(node.props.children)

        Object.keys(node.props).forEach( k => {
            if (k !== 'children') {
                props[k] = node.props[k]
            }
        })
    }


    const _description_node = {
        parent      : parent,
        type        : node.type,
        props       : props,
        children    : []
    }
    children.forEach( c => {
        const c_node = makeDescriptionTree(c, _description_node, apiData)
        if (null != c_node) {
            _description_node.children.push(c_node)
        }
    })
    return _description_node
}

module.exports = makeDescriptionTree
