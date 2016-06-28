jest.dontMock('../DateTime.js')
# Spying on a mock moment gets overly complicated due to its implementation.
jest.dontMock('moment')

describe 'DateTime', ->
    React = ReactDOM = TestUtils = null
    DateTime = null
    date = null

    DATE_ISO_STRING = '2016-01-02T03:04:05.000Z'

    beforeEach ->
        date        = new Date(DATE_ISO_STRING)
        DateTime    = require '../DateTime.js'
        React       = require 'react'
        ReactDOM    = require 'react-dom'
        TestUtils   = require 'react-addons-test-utils'

    it 'renders semantic markup using <time>', ->
        date_doc = TestUtils.renderIntoDocument(
            <DateTime date=date  />
        )
        date_str = TestUtils.findRenderedDOMComponentWithTag(
            date_doc, 'time'
        )
        expect(
            ReactDOM.findDOMNode(date_str).getAttribute('datetime')
        ).toEqual(DATE_ISO_STRING)

    describe 'relative', ->
        it 'renders relative times when specified', ->
            date_doc = TestUtils.renderIntoDocument(
                <DateTime date=date relative=true />
            )
            expect(
                ReactDOM.findDOMNode(date_doc).textContent.indexOf('ago')
            ).toNotEqual(-1)

        it 'renders relative time when within hours cutoff', ->
            _date = new Date((new Date()).getTime() - 1000 * 60 * 60 * 1)
            date_doc = TestUtils.renderIntoDocument(
                <DateTime date=_date relative={hours: 2} />
            )
            expect(
                ReactDOM.findDOMNode(date_doc).textContent.indexOf('ago')
            ).toNotEqual(-1)

        it 'renders absolute time when outside of cutoff', ->
            _date = new Date((new Date()).getTime() - 1000 * 60 * 60 * 3)
            date_doc = TestUtils.renderIntoDocument(
                <DateTime date=_date relative={hours: 2} />
            )
            expect(
                ReactDOM.findDOMNode(date_doc).textContent.indexOf('ago')
            ).toEqual(-1)

        it 'renders relative time when within days cutoff', ->
            _date = new Date((new Date()).getTime() - 1000 * 60 * 60 * 24 * 2)
            date_doc = TestUtils.renderIntoDocument(
                <DateTime date=_date relative={days: 3} />
            )
            expect(
                ReactDOM.findDOMNode(date_doc).textContent.indexOf('ago')
            ).toNotEqual(-1)
