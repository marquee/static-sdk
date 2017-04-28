const React = require('react')
const GalleryBlock = require('../GalleryBlock')
const renderer = require('react-test-renderer')

const SAMPLE_BLOCK = require('./SAMPLE_ENTRY.json').content.find( block => 'gallery' === block.type)

describe('GalleryBlock', () => {
    it('renders', () => {
        const component = renderer.create(
            React.createElement(GalleryBlock, { block: SAMPLE_BLOCK })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
    it('renders plain', () => {
        const component = renderer.create(
            React.createElement(GalleryBlock, { block: SAMPLE_BLOCK, plain: true })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
})
