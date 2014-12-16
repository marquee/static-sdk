# detect any lang-cjsx code elements
# compile
# add compiled to page as text
# add compiled to fragment as html
# if fragment has innerText, show it on page

React = require 'react'
window.React = React

CJSX = require 'coffee-react'

{ Byline } = require '../../components'
{ prettyPrint } = require 'html'
window.Byline = Byline

for code_block in document.querySelectorAll('code.lang-cjsx')
    do ->
        _source = code_block.innerText
        _source = """
            return #{ _source }
        """
        console.log _source
        _compiled = CJSX.compile(_source, bare: true)
        _compiledFn = new Function(_compiled)
        console.log _compiled
        _component = _compiledFn()
        _evaluated = React.renderComponentToStaticMarkup(_component)

        _compiled_display = document.createElement('div')
        console.log _evaluated
        console.log prettyPrint(_evaluated)
        _compiled_display.innerHTML = prettyPrint(_evaluated).replace(/&/g,'&amp;').replace(/\</g,'&lt;').replace(/\>/g,'&gt;')
        _compiled_display.style.whiteSpace = 'pre'
        code_block.parentElement.parentElement.insertBefore(_compiled_display, code_block.parentElement.nextSibling)

        _evaluated_display = document.createElement('div')
        _evaluated_display.innerHTML = _evaluated
        if _evaluated_display.innerText.trim()
            code_block.parentElement.parentElement.insertBefore(_evaluated_display, code_block.parentElement.nextSibling)


