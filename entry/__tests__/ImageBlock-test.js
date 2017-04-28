const React = require('react')
const ImageBlock = require('../ImageBlock')
const renderer = require('react-test-renderer')

const SAMPLE_BLOCK = require('./SAMPLE_ENTRY.json').content.find( block => 'image' === block.type)

describe('ImageBlock', () => {
    it('renders', () => {
        const component = renderer.create(
            React.createElement(ImageBlock, { block: SAMPLE_BLOCK })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
    it('renders plain', () => {
        const component = renderer.create(
            React.createElement(ImageBlock, { block: SAMPLE_BLOCK, plain: true })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
})
