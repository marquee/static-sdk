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
    it('takes sizes', () => {
        const component = renderer.create(
            React.createElement(ContentImage, { src: SAMPLE_BLOCK, sizes: '(min-width: 2560px) 2560px,(min-width: 1280px) 1280px,(min-width: 640px) 640px,100vw' })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
})
