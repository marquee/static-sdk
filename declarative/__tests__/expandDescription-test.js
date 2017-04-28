jest.autoMockOff()


describe('expandDescription', () => {
    const makeDescriptionTree       = require('../makeDescriptionTree')
    const expandDescription         = require('../expandDescription')
    const React                     = require('react')
    const { HTMLView, Enumerate }   = require('../Site')

    const r = React.createElement


    it('should expand the description', () => {
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                    r(Enumerate, { items: [{slug: 'a'}, {slug: 'b'}, {slug: 'c'}] },
                        r(HTMLView, { props: s => s, name: 'story_detail', path: s => s.slug, linkKey: s => s, component: () => r('div') })
                    )
                )
            )
        )
        expect(
            expanded
        ).toMatchSnapshot()
        expect(expanded.children.length).toEqual(4)
        expect(expanded.children[0].props.name).toEqual('about')
        expect(expanded.children[1].props.name).toEqual('story_detail')
    })

    it('should throw if given an enumeration without items', () => {
        expect( () => {
            expandDescription(
                makeDescriptionTree(
                    r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                        r(Enumerate, { },
                            r(HTMLView, { props: s => s, name: 'story_detail', path: s => s.slug, linkKey: s => s, component: () => r('div') })
                        )
                    )

                )
            )
        }).toThrow()
    })

    it('should expand nested enumerates', () => {
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                    r(Enumerate, { items: [{slug: 'a'}, {slug: 'b'}, {slug: 'c'}] },
                        r(HTMLView, { props: c => c, name: 'collection_detail', path: c => c.slug, linkKey: c => c, component: () => r('div') },
                            r(Enumerate, { items: () => ([{slug: 'x'}, {slug: 'y'}, {slug: 'z'}]) },
                                r(HTMLView, { props: c => c, name: 'story_detail', path: c => c.slug, linkKey: c => c, component: () => r('div') })
                            )
                        )
                    )
                )
            )
        )
        expect(
            expanded
        ).toMatchSnapshot()
        expect(expanded.children.length).toEqual(4)
        expect(expanded.children[0].props.name).toEqual('about')
        expect(expanded.children[1].props.name).toEqual('collection_detail')
        expect(expanded.children[1].children.length).toEqual(3)
        expect(expanded.children[1].children[0].props.name).toEqual('story_detail')
    })

    it('should omit children of empty enumerate items', () => {
        const expanded = expandDescription(
            makeDescriptionTree(
                r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                    r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                    r(Enumerate, { items: [] },
                        r(HTMLView, { props: c => c, name: 'collection_detail', path: c => c.slug, linkKey: c => c, component: () => r('div') })
                    )
                )
            )
        )
        expect(
            expanded
        ).toMatchSnapshot()
        expect(expanded.children.length).toEqual(1)
    })

})