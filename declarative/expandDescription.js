// @flow
const EnumerationItem   = require('./EnumerationItem')
const React             = require('react')
const { Enumerate }     = require('./Site')
const {reallyMapDataToProps} = require("./utils.js")

const _ = require("lodash")
/*::
type NodePropsType = {
    props           : ?(Object | Function),
    items           : ?(Array<any> | Function),
    name            : ?string,
    path            : ?(string | Function),
    linkKey         : ?(string | Function | Object),
}
type DescriptorNodeType = {
    children        : Array<DescriptorNodeType>,
    parent          : ?DescriptorNodeType,
    props           : NodePropsType,
    type            : Object,
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

function _expandDescription (node/*: DescriptorNodeType */, parent/*: ?ExpandedDescriptorNode */, enumeration/*: ?EnumerationItem */)/*: Array<ExpandedDescriptorNode>*/ {
    const to_return = []
    if (Enumerate === node.type) {

        let items
        if (null != node.props.items){
            items = node.props.items
        }else if(null != node.props.data){
            const realProps = reallyMapDataToProps(node.props.apiData, {"items" : node.props.data})
            items = realProps.items
        }else{
            throw new Error('Enumerate not given items. Must be an Array or function that returns an Array.')
        }

        let items_array = []
        if (null == items) {
            throw new Error('Enumerate not given items. Must be an Array or function that returns an Array.')
        }
        if ('function' === typeof items) {
            if (null != enumeration) {
                items_array = items(...enumeration.asIterateeArgs())
            } else {
                items_array = items()
            }
        } else {
            items_array = items
        }
        if (null == items_array || null == items_array.forEach) {
            throw new Error('Enumerate items function did not return an iterable with a forEach.')
        }
        items_array.forEach( (item, index) => {
            const _e = new EnumerationItem({ items: items_array, index, item, path: node.props.path })
            node.children.forEach( child => {
                to_return.push(..._expandDescription(child, parent, _e))
            })
        })
    }
    else {
        const expanded_node/*: ExpandedDescriptorNode */= {
            parent          : parent,
            type            : node.type,
            props           : node.props,
            children        : [],
            enumeration     : enumeration,
            gathered_props  : null,
            evaluated_path  : null, // <- move path evaluation to here?
            link_key        : null,
        }
        node.children.forEach( child => {
            expanded_node.children.push(
                ..._expandDescription(child, expanded_node, enumeration)
            )
        })
        to_return.push(expanded_node)
    }

    return to_return
}

function expandDescription (node/*: DescriptorNodeType */)/*:ExpandedDescriptorNode*/ {
    const expanded = _expandDescription(node)[0]
    return expanded
}

module.exports = expandDescription
module.exports.EnumerationItem = EnumerationItem
