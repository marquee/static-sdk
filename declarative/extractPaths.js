// @flow

const EnumerationItem = require('./EnumerationItem')

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
type PathMap = Map<string, Array<any>>
*/

function extractPaths (root_node/*: DescriptorNodeType */)/*: PathMap */ {

    const named_paths = new Map()

    function _traverse (node/*: DescriptorNodeType*/) {
        const node_name = node.props.name
        if (null != node_name) {
            if (named_paths.has(node_name)) {
                throw new Error(`Duplicate path name: ${ node_name }`)
            }
            const path_to_node = []

            let n = node
            while (null != n) {
                if (null != n.props.path) {
                    path_to_node.unshift(n.props.path)
                }
                n = n.parent
            }

            named_paths.set(node_name, path_to_node)
        }
        node.children.forEach( c => _traverse(c))
    }
    _traverse(root_node)

    return named_paths
}

module.exports = extractPaths