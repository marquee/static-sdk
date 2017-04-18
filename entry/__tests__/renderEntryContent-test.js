const React = require('react')
const renderEntryContent = require('../renderEntryContent')
const renderer = require('react-test-renderer')

const SAMPLE_ENTRY = require('./SAMPLE_ENTRY.json')

describe('renderEntryContent', () => {
    it('renders', () => {
        const component = renderer.create(
            React.createElement('div', null, ...renderEntryContent(SAMPLE_ENTRY.content))
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })

    it('renders plain', () => {
        const component = renderer.create(
            React.createElement('div', null, ...renderEntryContent(SAMPLE_ENTRY.content, { plain: true }))
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })

    it('renders plain', () => {
        const component = renderer.create(
            React.createElement('div', null, ...renderEntryContent([]))
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })
})
