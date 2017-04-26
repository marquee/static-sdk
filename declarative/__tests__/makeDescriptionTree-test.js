jest.autoMockOff()

describe('makeDescriptionTree', () => {
    const makeDescriptionTree           = require('../makeDescriptionTree')
    const React                         = require('react')
    const { HTMLView, Enumerate, Skip } = require('../Site')

    const r = React.createElement

    it('should parse the description', () => {
        const mock_description = (
            r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                r(Enumerate, { items: [{slug: 'a'}, {slug: 'b'}, {slug: 'c'}] },
                    r(HTMLView, { props: s => s, name: 'story_detail', path: s => s.slug, linkKey: s => s, component: () => r('div') })
                )
            )
        )
        expect(
            makeDescriptionTree(mock_description)
        ).toMatchSnapshot()
    })

    it('should skip Skips', () => {
        const mock_description = (
            r(HTMLView, { props: {}, name: 'home', path: '/', component: () => r('div') },
                r(HTMLView, { props: {}, name: 'about', path: 'about', component: () => r('div') }),
                r(Skip, null,
                    r(Enumerate, { items: [{slug: 'a'}, {slug: 'b'}, {slug: 'c'}] },
                        r(HTMLView, { props: s => s, name: 'story_detail', path: s => s.slug, linkKey: s => s, component: () => r('div') })
                    ),
                )
            )
        )
        expect(
            makeDescriptionTree(mock_description)
        ).toMatchSnapshot()
    })

})