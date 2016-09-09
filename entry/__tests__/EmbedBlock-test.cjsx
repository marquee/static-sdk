jest.dontMock('../EmbedBlock.js')
jest.dontMock('url')

describe 'EmbedBlock', ->
    describe 'parseVideoURL', ->
        it 'handles YouTube links', ->
            { parseVideoURL } = require '../EmbedBlock.js'
            
            expect(
                parseVideoURL('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
            ).toEqual('//www.youtube.com/embed/dQw4w9WgXcQ?modestbranding=1')

            expect(
                parseVideoURL('https://youtu.be/dQw4w9WgXcQ')
            ).toEqual('//www.youtube.com/embed/dQw4w9WgXcQ?modestbranding=1')

        it 'handles Vimeo links', ->
            { parseVideoURL } = require '../EmbedBlock.js'
            
            expect(
                parseVideoURL('https://vimeo.com/168590856')
            ).toEqual('//player.vimeo.com/video/168590856')

            expect(
                parseVideoURL('http://player.vimeo.com/video/168590856')
            ).toEqual('//player.vimeo.com/video/168590856')
