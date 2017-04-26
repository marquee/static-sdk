jest.autoMockOff()


describe('extractLinks', () => {
    // Using the whole chain since creating suitable mock objects manually
    // would be tedious or essentially duplicating what these do.
    const makeDescriptionTree       = require('../makeDescriptionTree')
    const expandDescription         = require('../expandDescription')
    const extractLinks              = require('../extractLinks')
    const React                     = require('react')
    const { HTMLView, Enumerate }   = require('../Site')

    const r = React.createElement

    it('should extract links', () => {

        const mock_collection = { slug: 'a' }
        const mock_story = { slug: 'x' }
        const other_mock_story = { slug: 'y' }
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                    r(Enumerate, { items: [mock_collection] },
                        r(HTMLView, { props: c => c, name: 'collection_detail', path: c => c.slug, linkKey: c => c, component: () => r('div') },
                            r(Enumerate, { items: [mock_story, other_mock_story, {slug: 'z'}] },
                                r(HTMLView, { props: c => c, name: 'story_detail', path: c => c.slug, linkKey: c => c, component: () => r('div') })
                            )
                        )
                    )
                )
            )
        )
        const links = extractLinks(expanded)
        expect(
            links
        ).toMatchSnapshot()
        expect(links.get('home')).toEqual('/')
        expect(links.get('about')).toEqual('/about/')
        expect(links.get('collection_detail').get(mock_collection)).toEqual('/a/')
        expect(links.get('story_detail').get(mock_story)).toEqual('/a/x/')
        expect(links.get('story_detail').get(other_mock_story)).toEqual('/a/y/')
    })


    it('should fail on duplicate singleton names', () => {
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                    r(HTMLView, { props: {}, name: 'about', path: 'about2', component: () => r('div') }),
                )
            )
        )
        expect( () => extractLinks(expanded) ).toThrow()
    })

    it('should fail on duplicate names and keys', () => {
        const mock_story = {slug: 'x'}
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'story_detail', linkKey: () => mock_story, path: s => s.slug, component: () => r('div') }),
                    r(HTMLView, { props: {}, name: 'story_detail', linkKey: () => mock_story, path: s => s.slug, component: () => r('div') }),
                )
            )
        )
        expect( () => extractLinks(expanded) ).toThrow()
    })

    it('should fail on keying existing singleton name', () => {
        const mock_story = {slug: 'x'}
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'story_detail', path: 'story/', component: () => r('div') }),
                    r(HTMLView, { props: {}, name: 'story_detail', linkKey: () => mock_story, path: s => s.slug, component: () => r('div') }),
                )
            )
        )
        expect( () => extractLinks(expanded) ).toThrow()
    })

    it('should fail on reusing a keyed name for a singleton', () => {
        const mock_story = {slug: 'x'}
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'story_detail', linkKey: () => mock_story, path: s => s.slug, component: () => r('div') }),
                    r(HTMLView, { props: {}, name: 'story_detail', path: 'story/', component: () => r('div') }),
                )
            )
        )
        expect( () => extractLinks(expanded) ).toThrow()
    })

})