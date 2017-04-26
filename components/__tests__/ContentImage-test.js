const React = require('react')
const ContentImage = require('../ContentImage')
const renderer = require('react-test-renderer')

const SAMPLE_BLOCK = require('../../entry/__tests__/SAMPLE_ENTRY.json').content.find( block => 'image' === block.type)

describe('ContentImage', () => {
    it('renders', () => {
        const component = renderer.create(
            React.createElement(ContentImage, { src: SAMPLE_BLOCK })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
    it('renders plain', () => {
        const component = renderer.create(
            React.createElement(ContentImage, { src: SAMPLE_BLOCK, plain: true })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
})
