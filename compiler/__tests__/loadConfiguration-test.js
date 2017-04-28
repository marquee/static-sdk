jest.autoMockOff()

describe('loadConfiguration', () => {
    let loadConfiguration

    beforeEach( () => {
        loadConfiguration = require('../loadConfiguration')
    })

    it('should fail if package.proof is not defined', () => {
        expect( () => loadConfiguration({})).toThrow()
    })

    it('should extract configuration from specification in package', () => {
        const pkg = {
            other_prop: {},
            proof: {
                CONTENT_API_TOKEN: 'a',
                AWS_ACCESS_KEY_ID: 'b',
                arbitrary: {
                    props: true,
                },
            }
        }
        const config = loadConfiguration(pkg)
        expect(config).toEqual(pkg.proof)
    })

    it('should ignore configurations when unspecified', () => {
        const pkg = {
            other_prop: {},
            proof: {
                CONTENT_API_TOKEN: 'a',
                AWS_ACCESS_KEY_ID: 'b',
                arbitrary: {
                    props: true,
                },
                configurations: {
                    production: {
                        CONTENT_API_TOKEN: 'c',
                    },
                    staging: {
                        CONTENT_API_TOKEN: 'd',
                    },
                },
            },
        }
        const config = loadConfiguration(pkg)
        expect(config).toEqual({
            CONTENT_API_TOKEN: 'a',
            AWS_ACCESS_KEY_ID: 'b',
            arbitrary: {
                props: true,
            },
        })
    })

    it('should composite a configuration if a name is specified', () => {
        const pkg = {
            other_prop: {},
            proof: {
                CONTENT_API_TOKEN: 'a',
                AWS_ACCESS_KEY_ID: 'b',
                arbitrary: {
                    props: true,
                },
                configurations: {
                    production: {
                        CONTENT_API_TOKEN: 'c',
                    },
                    staging: {
                        CONTENT_API_TOKEN: 'd',
                    },
                },
            },
        }
        const config = loadConfiguration(pkg, 'production')
        expect(config).toEqual({
            AWS_ACCESS_KEY_ID: 'b',
            arbitrary: {
                props: true,
            },
            CONTENT_API_TOKEN: 'c',
        })
    })
})