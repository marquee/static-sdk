jest.dontMock('../NOAT.js')

describe 'NOAT', ->

    NOAT = null

    beforeEach ->
        NOAT = require '../NOAT.js'

    it 'should handle empty strings', ->
        markup = new NOAT('')
        expect(markup.toString()).toEqual('')

    it 'should handle empty strings with annotations', ->
        markup = new NOAT('')
        markup.add('em', 0)
        expect(markup.toString()).toEqual('<em></em>')

    it 'should handle no annotations', ->
        markup = new NOAT('0123456789')
        expect(markup.toString()).toEqual('0123456789')

    it 'should handle a single substring annotation', ->
        markup = new NOAT('0123456789')
        markup.add('em', 3, 7)
        expect(markup.toString()).toEqual('012<em>3456</em>789')

    it 'should handle a single substring annotation with unicode', ->
        markup = new NOAT('0123456789é')
        markup.add('em', 3, 7)
        expect(markup.toString()).toEqual('012<em>3456</em>789é')

    it 'should handle a single annotation with a single attribute', ->
        markup = new NOAT('0123456789')
        markup.add('a', 1, 4, {href:'/'})
        expect(markup.toString()).toEqual('0<a href="/">123</a>456789')

    it 'should handle a single annotation with a single unicode attribute', ->
        markup = new NOAT('0123456789')
        markup.add('a', 1, 4, {class: 'é'})
        expect(markup.toString()).toEqual('0<a class="é">123</a>456789')

    it 'should handle a single annotation with a single entity-filled attribute', ->
        markup = new NOAT('0123456789')
        markup.add('a', 1, 4, {href: '?foo=false&bar=true'})
        expect(markup.toString()).toEqual('0<a href="?foo=false&amp;bar=true">123</a>456789')

    it 'should handle a single annotation with multiple attributes', ->
        markup = new NOAT('0123456789')
        markup.add('a', 1, 4, {href:'/', id:'foo'})
        expect(markup.toString()).toEqual('0<a href="/" id="foo">123</a>456789')

    it 'should handle a single annotation of the entire string', ->
        markup = new NOAT('0123456789')
        markup.add('strong', 0, 10)
        expect(markup.toString()).toEqual('<strong>0123456789</strong>')

    it 'should handle a multiple non-overlapping annotations', ->
        markup = new NOAT('0123456789')
        markup.add('strong', 0, 3)
        markup.add('em', 6, 8)
        expect(markup.toString()).toEqual('<strong>012</strong>345<em>67</em>89')

    it 'should handle a multiple overlapping annotations', ->
        markup = new NOAT('0123456789')
        markup.add('a', 1, 4, {href:'/'})
        markup.add('em', 3, 7)
        expect(markup.toString()).toEqual('0<a href="/">12<em>3</em></a><em>456</em>789')

    it 'should handle a multiple adjacent annotations', ->
        markup = new NOAT('0123456789')
        markup.add('a', 1, 4, {href:'/'})
        markup.add('em', 4, 7)
        expect(markup.toString()).toEqual('0<a href="/">123</a><em>456</em>789')

    it 'should handle floats as a range', ->
        markup = new NOAT('0123456789')
        markup.add('em', 4.1, 6.8)
        expect(markup.toString()).toEqual('0123<em>45</em>6789')

    it 'should handle a collapsed range', ->
        markup = new NOAT('0123456789')
        markup.add('span', 4, { 'class': 'marker' })
        expect(markup.toString()).toEqual('0123<span class="marker"></span>456789')

    it 'should handle the substitute class property name', ->
        markup = new NOAT('0123456789')
        markup.add('span', 4, 5, _class: 'marker')
        expect(markup.toString()).toEqual('0123<span class="marker">4</span>56789')

    it 'should not allow backward ranges', ->
        markup = new NOAT('0123456789')
        markup.add('em', 7, 4)
        expect(markup.toString()).toEqual('0123456789')

    it 'should not allow out-of-bounds ranges', ->
        markup = new NOAT('0123456789')
        markup.add('em', -3, 4)
        markup.add('em', 5, 100)
        expect(markup.toString()).toEqual('0123456789')

    it 'should escape HTML entities in text but preserve range positions', ->
        markup = new NOAT('0123<&6789')
        markup.add('em', 3, 7)
        expect(markup.toString()).toEqual('012<em>3&lt;&amp;6</em>789')

