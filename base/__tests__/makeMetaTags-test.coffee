jest.dontMock('../makeMetaTags.js')

describe 'makeMetaTags', ->
    it 'generates a list of meta tag elements', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        makeMetaTags = require '../makeMetaTags.js'
        TestUtils = require 'react-addons-test-utils'

        TAGS =
            'description'       : 'test description'
            'twitter:creator'   : 'marquee'
            'pubdate'           : '2016-01-01'

        tags = makeMetaTags(TAGS)

        tags.forEach (tag) ->
            tag_dom = TestUtils.renderIntoDocument(tag)
            tag_node = ReactDOM.findDOMNode(tag_dom)
            expect(tag_node.content).toEqual(TAGS[tag_node.name])

    it 'correctly handles Facebook OG tags with property instead of name', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        makeMetaTags = require '../makeMetaTags.js'
        TestUtils = require 'react-addons-test-utils'

        TAGS =
            'og:description'    : 'test description'
            'og:type'           : 'article'

        tags = makeMetaTags(TAGS)

        tags.forEach (tag) ->
            tag_dom = TestUtils.renderIntoDocument(tag)
            tag_node = ReactDOM.findDOMNode(tag_dom)
            expect(tag_node.content).toEqual(TAGS[tag_node.getAttribute('property')])
