/*
https://github.com/marquee/noat
 */
var NOAT, _addTextAnnotations, _closeTag, _escapeHTML, _openTag;

NOAT = (function() {
  function NOAT(text) {
    this.text = text;
    this.annotations = [];
    this._markup = null;
  }


  /*
  Public: add an annotation to the list of annotations to be applied.
  
  * tag   - A string to be used as the tag, eg `'em'` becomes `<em>`/`</em>`.
  * start - An integer that is the text position of the open tag.
  * end   - (optional) - An integer that is the test position of the closing tag.
              If not provided, the start is used (ie the tag is opened and then
              closed immediately, eg `...blah<span></span>blah...`).
  * attrs - (optional) - An object of key-value attributes to be added to
              the tag, eg `{ 'id': 'foo' }` becomes `id="foo"`.
   */

  NOAT.prototype.add = function(tag, start, end_or_attrs, attrs) {
    var end;
    if (attrs == null) {
      attrs = {};
    }
    if (arguments.length > 4) {
      throw new Error("add() takes 2, 3 or 4 arguments (" + arguments.length + " given)");
    }
    if (typeof end_or_attrs !== 'number') {
      end = start;
      attrs = end_or_attrs;
    } else {
      end = end_or_attrs;
    }
    if (!end) {
      end = start;
    }
    start = parseInt(start);
    end = parseInt(end);
    if (this._validateRange(start, end)) {
      this.annotations.push({
        tag: tag,
        start: start,
        end: end,
        attrs: attrs
      });
      return this._markup = null;
    }
  };

  NOAT.prototype._applyAnnotations = function() {
    return this._markup = _addTextAnnotations(this.text, this.annotations);
  };

  NOAT.prototype.toString = function() {
    if (this._markup == null) {
      this._applyAnnotations();
    }
    return this._markup;
  };

  NOAT.prototype._validateRange = function(start, end) {
    if (start > end) {
      return false;
    }
    if (start < 0) {
      return false;
    }
    if (end > this.text.length) {
      return false;
    }
    return true;
  };

  return NOAT;

})();

_openTag = function(t) {
  var attrs, k, ref, v;
  attrs = '';
  ref = t.attrs;
  for (k in ref) {
    v = ref[k];
    if (k === '_class') {
      k = 'class';
    }
    attrs += " " + k + "=\"" + (_escapeHTML(v)) + "\"";
  }
  return "<" + t.tag + attrs + ">";
};

_closeTag = function(t) {
  return "</" + t.tag + ">";
};

_addTextAnnotations = function(text, annotations) {
  var a, annotation_index_by_end, annotation_index_by_start, bound, end, i, j, k, l, len, len1, len2, len3, m, n, name, name1, o_tag, open_tags, output, ref, seg_text, segment_boundaries, segments, start, t, tags_to_close, tags_to_open, tags_to_reopen, v;
  annotation_index_by_start = {};
  annotation_index_by_end = {};
  for (j = 0, len = annotations.length; j < len; j++) {
    a = annotations[j];
    if (annotation_index_by_start[name = a['start']] == null) {
      annotation_index_by_start[name] = [];
    }
    annotation_index_by_start[a['start']].push(a);
    if (a['start'] !== a['end']) {
      if (annotation_index_by_end[name1 = a['end']] == null) {
        annotation_index_by_end[name1] = [];
      }
      annotation_index_by_end[a['end']].push(a);
    }
  }
  segment_boundaries = [];
  for (k in annotation_index_by_start) {
    v = annotation_index_by_start[k];
    segment_boundaries.push(parseInt(k));
  }
  for (k in annotation_index_by_end) {
    v = annotation_index_by_end[k];
    segment_boundaries.push(parseInt(k));
  }
  segment_boundaries.sort(function(a, b) {
    return a - b;
  });
  if (segment_boundaries.length === 0 || segment_boundaries[0] !== 0) {
    segment_boundaries.unshift(0);
  }
  if (segment_boundaries[segment_boundaries.length - 1] !== text.length) {
    segment_boundaries.push(text.length);
  }
  segments = [];
  ref = segment_boundaries.slice(0, -1);
  for (i in ref) {
    bound = ref[i];
    start = bound;
    end = segment_boundaries[parseInt(i) + 1];
    if (start !== end) {
      segments.push(text.substring(start, end));
    }
  }
  if (segments.length === 0) {
    segments.push('');
  }
  output = '';
  open_tags = [];
  i = 0;
  for (l = 0, len1 = segments.length; l < len1; l++) {
    seg_text = segments[l];
    tags_to_open = annotation_index_by_start[i] || [];
    tags_to_close = annotation_index_by_end[i] || [];
    tags_to_reopen = [];
    for (m = 0, len2 = tags_to_close.length; m < len2; m++) {
      t = tags_to_close[m];
      while (open_tags.length > 0 && t['tag'] !== open_tags[open_tags.length - 1]['tag']) {
        o_tag = open_tags.pop();
        output += _closeTag(o_tag);
        tags_to_reopen.push(o_tag);
      }
      output += _closeTag(t);
      open_tags.pop();
      while (tags_to_reopen.length > 0) {
        o_tag = tags_to_reopen.pop();
        output += _openTag(o_tag);
        open_tags.push(o_tag);
      }
    }
    for (n = 0, len3 = tags_to_open.length; n < len3; n++) {
      t = tags_to_open[n];
      output += _openTag(t);
      if (t['start'] !== t['end']) {
        open_tags.push(t);
      } else {
        output += _closeTag(t);
      }
    }
    output += _escapeHTML(seg_text).replace(/\n/g, '<br />');
    i += seg_text.length;
  }
  while (open_tags.length > 0) {
    o_tag = open_tags.pop();
    output += _closeTag(o_tag);
  }
  return output;
};

_escapeHTML = function(str) {
  if (typeof str !== 'string') {
    str = str.toString();
  }
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
};

module.exports = NOAT;