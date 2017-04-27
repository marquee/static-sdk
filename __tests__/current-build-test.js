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

})