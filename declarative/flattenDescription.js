// @flow
const React         = require('react')
const { Enumerate } = require('./Site')



class EnumerationItem {
    /*::
    item: Object
    index: number
    items: Array<Object>
    next: ?Object
    previous: ?Object
    */
    constructor ({ items, item, index }) {
        this.item       = item
        this.index      = index
        this.items      = items
        this.next       = items.length >= index ? items[index + 1] : null
        this.previous   = items.length >= 0 && index > 0 ? items[index - 1] : null
    }

    asIterateeArgs ()/* [?Object, number, EnumerationItem]  */ {
        return [this.item, this.index, this]
    }
}

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
type FlattenedDescriptorNode = {
    enumeration     : ?EnumerationItem,
    children        : Array<FlattenedDescriptorNode>,
    parent          : ?FlattenedDescriptorNode,
    props           : NodePropsType,
    type            : Object,
}
*/

function _flattenDescription (node/*: DescriptorNodeType */, parent/*: ?FlattenedDescriptorNode */, enumeration/*: ?EnumerationItem */)/*: Array<FlattenedDescriptorNode>*/ {
    const to_return = []

    if (Enumerate === node.type) {
        let items = node.props.items
        let items_array = []

        if (null == items) {
            throw new Error('Enumerate not given items. Must be an Array or function that returns an Array.')
        }
        if ('function' === typeof items) {
            if (null != parent && null != enumeration) {
                items_array = items(...enumeration.asIterateeArgs())
            } else {
                items_array = items()
            }
        } else {
            items_array = items
        }
        if (!Array.isArray(items_array)) {
            throw new Error('Enumerate items function did not return an Array.')
        }
        items_array.forEach( (item, index) => {
            const _e = new EnumerationItem({ items: items_array, index, item })
            node.children.forEach( child => {
                to_return.push(..._flattenDescription(child, parent, _e))
            })
        })
    } else {
        const flattened_node/*: FlattenedDescriptorNode */= {
            parent          : parent,
            type            : node.type,
            props           : node.props,
            children        : [],
            enumeration     : enumeration,
        }
        node.children.forEach( child => {
            flattened_node.children.push(
                ..._flattenDescription(child, flattened_node)
            )
        })
        to_return.push(flattened_node)
    }

    return to_return
}

function flattenDescription (node/*: DescriptorNodeType */)/*:FlattenedDescriptorNode*/ {
    return _flattenDescription(node)[0]
}

module.exports = flattenDescription
module.exports.EnumerationItem = EnumerationItem