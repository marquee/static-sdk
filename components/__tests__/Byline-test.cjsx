jest.dontMock('../Byline.cjsx')

describe 'Byline', ->
    it 'renders byline text with single string name', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline='First Last' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(names.getDOMNode().textContent).toEqual('First Last')
        expect(label.getDOMNode().textContent).toEqual('By ')

    it 'renders byline text with single string name and different label', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline='First Last' label='Written by ' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(names.getDOMNode().textContent).toEqual('First Last')
        expect(label.getDOMNode().textContent).toEqual('Written by ')

    it 'renders byline text with two names', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline={['First Last','Other Name']} />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(names.getDOMNode().textContent).toEqual('First Last & Other Name')
    
    it 'renders byline text with three names', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline={['First Last','Other Name','Some Person']} />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(names.getDOMNode().textContent).toEqual('First Last, Other Name, & Some Person')
        
    it 'renders byline text with three names and different join/and', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline={['First Last','Other Name', 'Some Person']} join='|' and='AND' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        expect(names.getDOMNode().textContent).toEqual('First Last|Other Name|AND Some Person')

    it 'renders empty with no names in list', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline=[] />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(names.getDOMNode().textContent).toEqual('')
        expect(label.getDOMNode().textContent).toEqual('')

    it 'renders empty with no names in string', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline='' />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(names.getDOMNode().textContent).toEqual('')
        expect(label.getDOMNode().textContent).toEqual('')

    it 'renders empty with no names as null', ->
        React = require 'react/addons'
        Byline = require '../Byline.cjsx'
        { TestUtils } = React.addons

        byline = TestUtils.renderIntoDocument(
            <Byline byline=null />
        )

        names = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Names'
        )
        label = TestUtils.findRenderedDOMComponentWithClass(
            byline, '_Label'
        )
        expect(names.getDOMNode().textContent).toEqual('')
        expect(label.getDOMNode().textContent).toEqual('')
