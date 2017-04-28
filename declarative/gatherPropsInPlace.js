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
}*/

function gatherPropsInPlace (node/*: ExpandedDescriptorNode */) {

    let gathered_props
    const node_props        = node.props.props
    const node_enumeration  = node.enumeration
    if (null != node_props) {
        if ('function' === typeof node_props) {
            if (null != node_enumeration) {
                gathered_props = Object.assign({}, node_props(
                    ...node_enumeration.asIterateeArgs()
                ))
            } else {
                gathered_props = Object.assign({}, node_props())
            }
        } else {
            gathered_props = Object.assign({}, node_props)
        }
    } else {
        gathered_props = {}
    }

    node.gathered_props = gathered_props
    node.children.forEach(gatherPropsInPlace)
}

module.exports = gatherPropsInPlace