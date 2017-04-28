jest.autoMockOff()

describe('current-build', () => {
    let current_build

    const { BuildState } = require('../current-build')

    beforeEach( () => {
        current_build = new BuildState()
    })

    describe('config', () => {
        it('should fail if used before set up', () => {
            current_build.config // should do nothing (be importable)
            expect( () => current_build.config.HOST).toThrow()
        })

        it('should work if used after set up', () => {
            current_build.__setConfig({
                HOST: 'example.com',
                HTTPS: false,
            })
            expect(current_build.config.HOST).toEqual('example.com')
        })

        it('should work if imported before set up but accessed after', () => {
            const { config } = current_build
            expect( () => config.HOST).toThrow()
            current_build.__setConfig({
                HOST: 'example.com',
                HTTPS: false,
            })
            expect(config.HOST).toEqual('example.com')
        })

        it('should fail if write attempted', () => {
            current_build.__setConfig({
                HOST: 'example.com',
                HTTPS: false,
            })
            expect( () => current_build.config.HOST = 'baz.bar').toThrow()
        })

        it('should work if used after close up', () => {
            expect( () => current_build.config.HOST).toThrow()
            current_build.__setConfig({
                HOST: 'example.com',
                HTTPS: false,
            })
            expect(current_build.config.HOST).toEqual('example.com')
            current_build.__close()
            expect(current_build.config.HOST).toEqual('example.com')
        })

        it('should fail if unknown property', () => {
            current_build.__setConfig({
                HOST: 'example.com',
                HTTPS: false,
            })
            expect( () => current_build.config.TITLE).toThrow()
        })
    })

    describe('linkTo', () => {
        it('should fail if used before set up', () => {
            expect( () => current_build.linkTo('view')).toThrow()
        })

        it('should work for singleton links', () => {
            const site_links = new Map()
            site_links.set('view', '/baz/')
            current_build.__setLinks(site_links)
            expect(current_build.linkTo('view')).toEqual('/baz/')
        })

        it('should fail for unknown links', () => {
            const site_links = new Map()
            site_links.set('view', '/baz/')
            current_build.__setLinks(site_links)
            expect(() => current_build.linkTo('view2')).toThrow()
        })

        it('should work with key objects', () => {
            const site_links = new Map()
            const view_links = new Map()
            const _obj = { slug: 'baz' }
            site_links.set('view', view_links)
            view_links.set(_obj, '/baz/')
            current_build.__setLinks(site_links)
            expect(current_build.linkTo('view', _obj)).toEqual('/baz/')
        })

        it('should fail if key given for singleton link', () => {
            const site_links = new Map()
            const _obj = { slug: 'baz' }
            site_links.set('view', '/about/')
            current_build.__setLinks(site_links)
            expect( () => current_build.linkTo('view', _obj)).toThrow()
        })

        it('should fail if used after close up', () => {
            const site_links = new Map()
            const _obj = { slug: 'baz' }
            site_links.set('view', '/about/')
            current_build.__setLinks(site_links)
            current_build.__close()
            expect( () => current_build.linkTo('view')).toThrow()
        })
    })


    describe('linkToPath', () => {
        it('should fail if used before set up', () => {
            expect( () => current_build.linkToPath('view')).toThrow()
        })

        it('should work for basic paths', () => {
            const site_paths = new Map()
            site_paths.set('view', ['/','baz'])
            current_build.__setPaths(site_paths)
            expect(current_build.linkToPath('view')).toEqual('/baz/')
        })

        it('should fail for unknown paths', () => {
            const site_paths = new Map()
            site_paths.set('view', ['/','baz'])
            current_build.__setLinks(site_paths)
            expect(() => current_build.linkToPath('view2')).toThrow()
        })

        it('should work for complex paths', () => {
            const site_paths = new Map()
            site_paths.set('view', ['/', 'collections', c => c.slug, 'stories', ({ s, c }) => s.slug])
            current_build.__setPaths(site_paths)
            const mock_story = { slug: 'bar' }
            const mock_collection = { slug: 'foo' }
            expect(
                current_build.linkToPath('view', mock_collection, { s: mock_story, c: mock_collection } )
            ).toEqual('/collections/foo/stories/bar/')
        })

        it('should fail if used after close up', () => {
            const site_paths = new Map()
            site_paths.set('view', ['/','baz'])
            current_build.__setPaths(site_paths)
            current_build.__close()
            expect( () => current_build.linkToPath('view')).toThrow()
        })
    })

})