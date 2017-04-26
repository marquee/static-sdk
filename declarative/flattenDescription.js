// @flow

const React = require('react')
const EnumerationItem = require('./EnumerationItem')
/*::
type NodePropsType = {
    props           : ?(Object | Function),
    items           : ?(Array<any> | Function),
    name            : ?string,
    path            : ?(string | Function),
    linkKey         : ?(string | Function | Object),
}
type ExpandedDescriptorNode = {
    enumeration     : ?EnumerationItem,
    children        : Array<ExpandedDescriptorNode>,
    parent          : ?ExpandedDescriptorNode,
    props           : NodePropsType,
    type            : Object,
    evaluated_path  : ?string,
    link_key        : ?any,
    gathered_props  : ?Object,
}
*/

function flattenDescription (node/*: ExpandedDescriptorNode */)/*: Array<ExpandedDescriptorNode>*/ {

    const all_nodes = [node]
    node.children.forEach( child => {
        all_nodes.push(...flattenDescription(child))
    })
    return all_nodes
}

module.exports = flattenDescription