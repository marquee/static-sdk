jest.dontMock('../NOAT');

describe('NOAT', function() {
  var NOAT;
  NOAT = null;
  beforeEach(function() {
    return NOAT = require('../NOAT');
  });
  it('should handle empty strings', function() {
    var markup;
    markup = new NOAT('');
    return expect(markup.toString()).toEqual('');
  });
  it('should handle empty strings with annotations', function() {
    var markup;
    markup = new NOAT('');
    markup.add('em', 0);
    return expect(markup.toString()).toEqual('<em></em>');
  });
  it('should handle no annotations', function() {
    var markup;
    markup = new NOAT('0123456789');
    return expect(markup.toString()).toEqual('0123456789');
  });
  it('should handle a single substring annotation', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('em', 3, 7);
    return expect(markup.toString()).toEqual('012<em>3456</em>789');
  });
  it('should handle a single substring annotation with unicode', function() {
    var markup;
    markup = new NOAT('0123456789é');
    markup.add('em', 3, 7);
    return expect(markup.toString()).toEqual('012<em>3456</em>789é');
  });
  it('should handle a single annotation with a single attribute', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('a', 1, 4, {
      href: '/'
    });
    return expect(markup.toString()).toEqual('0<a href="/">123</a>456789');
  });
  it('should handle a single annotation with a single unicode attribute', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('a', 1, 4, {
      "class": 'é'
    });
    return expect(markup.toString()).toEqual('0<a class="é">123</a>456789');
  });
  it('should handle a single annotation with a single entity-filled attribute', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('a', 1, 4, {
      href: '?foo=false&bar=true'
    });
    return expect(markup.toString()).toEqual('0<a href="?foo=false&amp;bar=true">123</a>456789');
  });
  it('should handle a single annotation with multiple attributes', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('a', 1, 4, {
      href: '/',
      id: 'foo'
    });
    return expect(markup.toString()).toEqual('0<a href="/" id="foo">123</a>456789');
  });
  it('should handle a single annotation of the entire string', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('strong', 0, 10);
    return expect(markup.toString()).toEqual('<strong>0123456789</strong>');
  });
  it('should handle a multiple non-overlapping annotations', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('strong', 0, 3);
    markup.add('em', 6, 8);
    return expect(markup.toString()).toEqual('<strong>012</strong>345<em>67</em>89');
  });
  it('should handle a multiple overlapping annotations', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('a', 1, 4, {
      href: '/'
    });
    markup.add('em', 3, 7);
    return expect(markup.toString()).toEqual('0<a href="/">12<em>3</em></a><em>456</em>789');
  });
  it('should handle a multiple adjacent annotations', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('a', 1, 4, {
      href: '/'
    });
    markup.add('em', 4, 7);
    return expect(markup.toString()).toEqual('0<a href="/">123</a><em>456</em>789');
  });
  it('should handle floats as a range', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('em', 4.1, 6.8);
    return expect(markup.toString()).toEqual('0123<em>45</em>6789');
  });
  it('should handle a collapsed range', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('span', 4, {
      'class': 'marker'
    });
    return expect(markup.toString()).toEqual('0123<span class="marker"></span>456789');
  });
  it('should handle the substitute class property name', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('span', 4, 5, {
      _class: 'marker'
    });
    return expect(markup.toString()).toEqual('0123<span class="marker">4</span>56789');
  });
  it('should not allow backward ranges', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('em', 7, 4);
    return expect(markup.toString()).toEqual('0123456789');
  });
  it('should not allow out-of-bounds ranges', function() {
    var markup;
    markup = new NOAT('0123456789');
    markup.add('em', -3, 4);
    markup.add('em', 5, 100);
    return expect(markup.toString()).toEqual('0123456789');
  });
  return it('should escape HTML entities in text but preserve range positions', function() {
    var markup;
    markup = new NOAT('0123<&6789');
    markup.add('em', 3, 7);
    return expect(markup.toString()).toEqual('012<em>3&lt;&amp;6</em>789');
  });
});