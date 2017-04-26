// @flow

const React = require('react')
const { Skip } = require('./Site')
/*::
type DescriptorNode = {
    parent: ?DescriptorNode,
    type: Object,
    props: Object,
    children: Array<DescriptorNode>,
}
*/

function makeDescriptionTree (node/*: React.Element<*> */, parent/*: ?DescriptorNode */)/*: ?DescriptorNode */ {
    if (Skip === node.type) {
        return null
    }
    const props = {}
    if (null != node.type.default_props) {
        Object.assign(props, node.type.default_props)
    }
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
        children    : [],
    }
    children.forEach( c => {
        const c_node = makeDescriptionTree(c, _description_node)
        if (null != c_node) {
            _description_node.children.push(c_node)
        }
    })
    return _description_node
}

module.exports = makeDescriptionTree