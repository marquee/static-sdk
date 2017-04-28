jest.autoMockOff()


describe('gatherPropsInPlace', () => {
    // Using the whole chain since creating suitable mock objects manually
    // would be tedious or essentially duplicating what these do.
    const makeDescriptionTree       = require('../makeDescriptionTree')
    const expandDescription         = require('../expandDescription')
    const gatherPropsInPlace        = require('../gatherPropsInPlace')
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
                    r(HTMLView, { props: { a: 1 }, name: 'about', path: 'about', component: () => r('div') }),
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
        gatherPropsInPlace(expanded)

        expect(expanded.children[0].gathered_props).toEqual({ a: 1 })
        expect(expanded.children[1].gathered_props).toEqual(mock_collection)
        expect(expanded.children[1].children[0].gathered_props).toEqual(mock_story)
    })
})