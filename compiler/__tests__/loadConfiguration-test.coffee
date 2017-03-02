jest.autoMockOff()

describe 'loadConfiguration', ->
    loadConfiguration = null

    beforeEach ->
        loadConfiguration = require '../loadConfiguration.js'

    it 'should fail if package.proof is not defined', ->
        expect(-> loadConfiguration({})).toThrow()

    it 'should extract configuration from specification in package', ->
        pkg =
            other_prop: {}
            proof:
                CONTENT_API_TOKEN: 'a'
                AWS_ACCESS_KEY_ID: 'b'
                arbitrary:
                    props: true
        config = loadConfiguration(pkg)
        expect(config).toEqual(pkg.proof)

    it 'should ignore configurations when unspecified', ->
        pkg =
            other_prop: {}
            proof:
                CONTENT_API_TOKEN: 'a'
                AWS_ACCESS_KEY_ID: 'b'
                arbitrary:
                    props: true
                configurations:
                    production:
                        CONTENT_API_TOKEN: 'c'
                    staging:
                        CONTENT_API_TOKEN: 'd'
        config = loadConfiguration(pkg)
        expect(config).toEqual
            CONTENT_API_TOKEN: 'a'
            AWS_ACCESS_KEY_ID: 'b'
            arbitrary:
                props: true

    it 'should composite a configuration if a name is specified', ->
        pkg =
            other_prop: {}
            proof:
                CONTENT_API_TOKEN: 'a'
                AWS_ACCESS_KEY_ID: 'b'
                arbitrary:
                    props: true
                configurations:
                    production:
                        CONTENT_API_TOKEN: 'c'
                    staging:
                        CONTENT_API_TOKEN: 'd'
        config = loadConfiguration(pkg, 'production')
        expect(config).toEqual
            AWS_ACCESS_KEY_ID: 'b'
            arbitrary:
                props: true
            CONTENT_API_TOKEN: 'c'

