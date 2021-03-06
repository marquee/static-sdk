// @flow

const React             = require('react')
const EmbedBlock        = require('./EmbedBlock')
const ImageBlock        = require('./ImageBlock')
const ListBlock         = require('./ListBlock')
const TextBlock         = require('./TextBlock')
const GalleryBlock      = require('./GalleryBlock')
const SectionBreakBlock = require('./SectionBreakBlock')

const TEXT              = 'text'
const IMAGE             = 'image'
const EMBED             = 'embed'
const LIST              = 'list'
const GALLERY           = 'gallery'
const SECTIONBREAK      = 'sectionbreak'

const DEFAULT_BLOCK_TYPE_MAP = {
    [TEXT]          : TextBlock,
    [IMAGE]         : ImageBlock,
    [EMBED]         : EmbedBlock,
    [LIST]          : ListBlock,
    [GALLERY]       : GalleryBlock,
    [SECTIONBREAK]  : SectionBreakBlock,
}

function renderEntryContent (content/*: Array<Object> */, options/*: { plain: boolean, intercept: { text?: Function, image?: Function, embed?: Function, list?: Function, gallery?: Function } } */={ plain: false, intercept: {} })/* Array<React.Element<*>> */ {
    if (null == content) {
        return []
    }

    const block_type_map = Object.assign({}, DEFAULT_BLOCK_TYPE_MAP, options.intercept)

    const result = content.map( block => {
        const block_props = {
            block   : block,
            key     : block.id,
            plain   : options.plain,
        }
        const block_type = block_type_map[block.type]
        if (null == block_type) {
            const _msg = `renderEntryContent got unknown block type: ${ block.type } (${ block.id })`
            if (process.env.NODE_ENV === 'production') {
                // Console instead of SDKError so this is client-safe.
                console.warn(_msg)
                return null
            } else {
                throw new Error(_msg)
            }
        }
        return React.createElement(block_type, block_props)
    })

    return result
}

module.exports = renderEntryContent
