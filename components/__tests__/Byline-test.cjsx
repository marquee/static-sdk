jest.dontMock('../Byline.js')

describe 'Byline', ->
    it 'renders byline text with single string name', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline='First Last' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('First Last')
        expect(ReactDOM.findDOMNode(label).textContent).toEqual('By ')

    it 'renders byline text with single string name and different label', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline='First Last' label='Written by ' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('First Last')
        expect(ReactDOM.findDOMNode(label).textContent).toEqual('Written by ')

    it 'renders byline text with two names', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline={['First Last','Other Name']} />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('First Last & Other Name')

    it 'renders byline text with two entities', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline={[ {name: 'First Last'}, {name: 'Other Name'} ]} />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('First Last & Other Name')

    it 'renders byline text with three names', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline={['First Last','Other Name','Some Person']} />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('First Last, Other Name, & Some Person')

    it 'doesn\'t modify original names', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        name_list = ['First Last','Other Name','Some Person']

        byline = TestUtils.renderIntoDocument(
            <Byline byline=name_list />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('First Last, Other Name, & Some Person')

        byline2 = TestUtils.renderIntoDocument(
            <Byline byline=name_list />
        )

        names2 = TestUtils.findRenderedDOMComponentWithClass(
            byline2, '_Names'
        )
        expect(ReactDOM.findDOMNode(names2).textContent).toEqual('First Last, Other Name, & Some Person')


    it 'renders byline text with three names and different join/and', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline={['First Last','Other Name', 'Some Person']} join='|' and='AND' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('First Last|Other Name|AND Some Person')

    it 'renders empty with no names in list', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline=[] />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('')
        expect(ReactDOM.findDOMNode(label).textContent).toEqual('')

    it 'renders empty with no names in string', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline='' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('')
        expect(ReactDOM.findDOMNode(label).textContent).toEqual('')

    it 'renders empty with no names as null', ->
        React = require 'react'
        ReactDOM = require 'react-dom'
        Byline = require '../Byline.js'
        TestUtils = require 'react-addons-test-utils'

        byline = TestUtils.renderIntoDocument(
            <Byline byline=null />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(ReactDOM.findDOMNode(names).textContent).toEqual('')
        expect(ReactDOM.findDOMNode(label).textContent).toEqual('')
