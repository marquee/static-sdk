const React = require('react')
const TextBlock = require('../TextBlock')
const renderer = require('react-test-renderer')

const SAMPLE_BLOCK = require('./SAMPLE_ENTRY.json').content.find( block => 'text' === block.type)

describe('TextBlock', () => {
    it('renders', () => {
        const component = renderer.create(
            React.createElement(TextBlock, { block: SAMPLE_BLOCK })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
    it('renders plain', () => {
        const component = renderer.create(
            React.createElement(TextBlock, { block: SAMPLE_BLOCK, plain: true })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
})
