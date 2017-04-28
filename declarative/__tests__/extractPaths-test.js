jest.autoMockOff()


describe('extractPaths', () => {
    // Using the whole chain since creating suitable mock objects manually
    // would be tedious or essentially duplicating what these do.
    const makeDescriptionTree       = require('../makeDescriptionTree')
    const expandDescription         = require('../expandDescription')
    const extractPaths              = require('../extractPaths')
    const React                     = require('react')
    const { HTMLView, Enumerate }   = require('../Site')

    const r = React.createElement

    it('should extract paths', () => {
        const cLinkFn = c => c.slug
        const sLinkFn = s => s.slug
        const mock_collection = { slug: 'a' }
        const mock_story = { slug: 'x' }
        const other_mock_story = { slug: 'y' }
        const tree = makeDescriptionTree(
            r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                r(Enumerate, { items: [mock_collection] },
                    r(HTMLView, { props: c => c, name: 'collection_detail', path: cLinkFn, linkKey: c => c, component: () => r('div') },
                        r(Enumerate, { items: [mock_story, other_mock_story, {slug: 'z'}] },
                            r(HTMLView, { props: c => c, name: 'story_detail', path: sLinkFn, linkKey: c => c, component: () => r('div') })
                        )
                    )
                ),
                r(HTMLView, { props: {}, name: 'raw_html', path: 'raw.html', component: () => r('div') }),
            )
        )
        const paths = extractPaths(tree)
        // expect(
        //     paths
        // ).toMatchSnapshot()
        expect(paths.get('home')).toEqual(['/'])
        expect(paths.get('about')).toEqual(['/','about'])
        expect(paths.get('raw_html')).toEqual(['/','raw.html'])
        expect(paths.get('collection_detail')).toEqual(['/',cLinkFn])
        expect(paths.get('story_detail')).toEqual(['/',cLinkFn, sLinkFn])
    })

    it('should handle Enumerates with paths', () => {

        const linkFn = c => c.slug
        const mock_collection = { slug: 'a' }
        const mock_story = { slug: 'x' }
        const other_mock_story = { slug: 'y' }
        const tree = makeDescriptionTree(
            r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                r(Enumerate, { path: 'stories', items: [mock_story, other_mock_story, {slug: 'z'}] },
                    r(HTMLView, { props: c => c, name: 'story_detail', path: linkFn, linkKey: c => c, component: () => r('div') })
                )
            )
        )
        const paths = extractPaths(tree)
        // expect(
        //     paths
        // ).toMatchSnapshot()
        expect(paths.get('home')).toEqual(['/'])
        expect(paths.get('story_detail')).toEqual(['/', 'stories', linkFn])
    })

    it('should fail on duplicate names', () => {
        const tree = makeDescriptionTree(
            r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                r(HTMLView, { props: {}, name: 'about', path: 'about2', component: () => r('div') }),
            )
        )
        expect( () => extractPaths(tree) ).toThrow()
    })

})