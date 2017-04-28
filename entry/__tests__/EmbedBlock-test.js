const React = require('react')
const EmbedBlock = require('../EmbedBlock')
const renderer = require('react-test-renderer')

const SAMPLE_BLOCK = require('./SAMPLE_ENTRY.json').content.find( block => 'embed' === block.type)

describe('EmbedBlock', () => {
    describe('parseVideoURL', () => {
        it('handles YouTube links', () => {
            const { parseVideoURL } = require('../EmbedBlock')
            
            expect(
                parseVideoURL('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
            ).toEqual('//www.youtube.com/embed/dQw4w9WgXcQ?modestbranding=1')

            expect(
                parseVideoURL('https://youtu.be/dQw4w9WgXcQ')
            ).toEqual('//www.youtube.com/embed/dQw4w9WgXcQ?modestbranding=1')
        })

        it('handles Vimeo links', () => {
            const { parseVideoURL } = require('../EmbedBlock')
            
            expect(
                parseVideoURL('https://vimeo.com/168590856')
            ).toEqual('//player.vimeo.com/video/168590856')

            expect(
                parseVideoURL('https://player.vimeo.com/video/168590856')
            ).toEqual('https://player.vimeo.com/video/168590856')
        })
    })

    it('renders', () => {
        const component = renderer.create(
            React.createElement(EmbedBlock, { block: SAMPLE_BLOCK })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })

    it('renders plain', () => {
        const component = renderer.create(
            React.createElement(EmbedBlock, { block: SAMPLE_BLOCK, plain: true })
        )
        expect(
            component.toJSON()
        ).toMatchSnapshot()
    })

})
