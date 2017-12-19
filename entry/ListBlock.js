// @flow

const React         = require('react')
const shiny         = require('shiny')
const TextBlock     = require('./TextBlock')

const ListBlock = (props) => {

    const tag_props = {}
    if (!props.plain) {
        tag_props.className = shiny('Block', 'ListBlock')
        tag_props.className.add({ role: props.block.role })
        tag_props.id = props.block.id
    }

    const tag = 'ordered' === props.block.role ? 'ol' : 'ul'
    const list_items = props.block.content.map( (subblock, i) => (
        React.createElement('li', {
            dangerouslySetInnerHTML: {
                __html: TextBlock.renderText(subblock.text, subblock.annotations, props.plain),
            },
        })
    ))

    return React.createElement(tag, tag_props, ...list_items)
}

ListBlock.defaultProps = {
    plain: false,
}

module.exports = ListBlock
