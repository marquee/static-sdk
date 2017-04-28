const React = require('react')
const ListBlock = require('../ListBlock')
const renderer = require('react-test-renderer')

const SAMPLE_BLOCKS = require('./SAMPLE_ENTRY.json').content.filter( block => 'list' === block.type)

describe('ListBlock', () => {
    it('renders', () => {
        SAMPLE_BLOCKS.forEach( block => {
            const component = renderer.create(
                React.createElement(ListBlock, { block: block })
            )
            expect(
                component.toJSON()
            ).toMatchSnapshot()
        })
    })
    it('renders plain', () => {
        SAMPLE_BLOCKS.forEach( block => {
            const component = renderer.create(
                React.createElement(ListBlock, { block: block, plain: true })
            )
            expect(
                component.toJSON()
            ).toMatchSnapshot()
        })
    })
})
