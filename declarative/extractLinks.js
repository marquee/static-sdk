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
type ExpandedDescriptorNode = {
    enumeration     : ?EnumerationItem,
    children        : Array<ExpandedDescriptorNode>,
    parent          : ?ExpandedDescriptorNode,
    props           : NodePropsType,
    type            : Object,
    evaluated_path  : ?string,
}
type LinkMatch = string | Map<any, string>
type LinkMap = Map<string, LinkMatch>
*/

function extractLinks (expanded_description/*: ExpandedDescriptorNode */)/*: LinkMap*/ {

    const named_links = new Map()

    function _traverse (node/*: ExpandedDescriptorNode*/, parent_path/*: string */) {
        const node_name = node.props.name
        const node_enumeration = node.enumeration

        let this_path = parent_path
        if (null != node_name) {
            const node_path/*: ?(string | Function) */ = node.props.path
            let node_path_string/*: ?any */
            if (null != node_path && 'function' === typeof node_path) {
                if (null != node_enumeration) {
                    node_path_string = node_path(...node_enumeration.asIterateeArgs())
                } else {
                    node_path_string = node_path()
                }
                if (null == node_path_string) {
                    throw new Error(`${ node_name } path iteratee did not return a string, got null`)
                } else if ('string' !== typeof node_path_string) {
                    throw new Error(`${ node_name } path iteratee did not return a string, got ${ typeof node_path_string }: ${ node_path_string }`)
                }
            } else if ('string' === typeof node_path) {
                node_path_string = node_path
            }

            if (null != node_path_string) {
                if (null != node_enumeration && null != node_enumeration.path) {
                    if ('string' === typeof node_enumeration.path) {
                        node_path_string = `${ node_enumeration.path }/${ node_path_string }`
                    } else {
                        throw new Error('Enumerate cannot use iteratee functions as paths')
                    }
                }
                this_path = `/${ parent_path }/${ node_path_string }/`.replace(/\/+/g,'/')
                const existing_link_def = named_links.get(node_name)
                const node_linkKey = node.props.linkKey
                if (null != node_linkKey) {
                    let node_key
                    if ('function' === typeof node_linkKey) {
                        if (null != node_enumeration) {
                            node_key = node_linkKey(...node_enumeration.asIterateeArgs())
                        } else {
                            node_key = node_linkKey()
                        }
                        if (null == node_key) {
                            throw new Error('linkKey returned null, must be non-null')
                        }
                    } else {
                        node_key = node_linkKey
                    }

                    let link_map
                    if (null != existing_link_def) {
                        if ('string' === typeof existing_link_def) {
                            throw new Error(`Link name already defined with singleton path: ${ node_name }, existing: ${ existing_link_def }`)
                        } else if (existing_link_def.has(node_key)) {
                            throw new Error(`Duplicate link name and key at: ${ node_name }, ${ node_key.toString() }`)
                        } else {
                            link_map = existing_link_def
                        }
                    } else {
                        link_map = new Map()
                    }

                    link_map.set(node_key, this_path)
                    named_links.set(node_name, link_map)
                } else {
                    if (null != existing_link_def) {
                        if ('string' !== typeof existing_link_def) {
                            throw new Error(`Link name already defined with keys: ${ node_name }`)
                        } else {
                            throw new Error(`Duplicate link name: ${ node_name }, existing: ${ existing_link_def }`)
                        }
                    }
                    named_links.set(node_name, this_path)
                }
                node.evaluated_path = this_path
            }
        }
        node.children.forEach( c => _traverse(c, this_path))
    }
    _traverse(expanded_description, '')

    return named_links
}

module.exports = extractLinks