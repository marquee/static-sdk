const renderEntryContentToString = require('../renderEntryContentToString')

const SAMPLE_ENTRY = require('./SAMPLE_ENTRY.json')

describe('renderEntryContentToString', () => {
    it('renders', () => {
        const string = renderEntryContentToString(SAMPLE_ENTRY.content)
        expect(
            string
        ).toMatchSnapshot()
    })

    it('renders plain', () => {
        const string = renderEntryContentToString(SAMPLE_ENTRY.content, { plain: true })
        expect(
            string
        ).toMatchSnapshot()
    })

    it('renders empty', () => {
        const string = renderEntryContentToString([])
        expect(
            string
        ).toMatchSnapshot()
    })
})
