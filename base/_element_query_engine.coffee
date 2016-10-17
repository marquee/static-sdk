# Adapted from https://github.com/tysonmatanich/elementQuery
clean = (element, attr) ->
    val = element.getAttribute(attr)
    return val?.replace?(/[\t\r\n]/g, ' ') or ''

addTo = (element, attr, value) ->
    if element.nodeType is 1 and value
        val = "#{ value }px"
        cur = clean(element, attr)
        if cur.indexOf(val) is -1
            element.setAttribute(attr, ("#{ cur } #{ val }").trim())

removeFrom = (element, attr, value) ->
    if element.nodeType is 1 and value
        val = "#{ value }px"
        cur = clean(element, attr)
        updated = false
        while (cur.indexOf(val) >= 0)
            cur = cur.replace(val, '')
            updated = true
        if updated
            element.setAttribute(attr, cur.trim())

pending_frame = null
frame_fns = []
refresh = ->
    frame_fns = []
    for selector, rules of _query_data
        do ->
            elements = document.querySelectorAll(selector)

            for element in elements
                for constraint, values of rules
                    values.forEach (value) ->

                        _element = element
                        _constraint = constraint

                        # NOTE: Using offsetWidth/Height so an element can be adjusted when it reaches a specific size.
                        # For Nested queries scrollWidth/Height or clientWidth/Height may sometime be desired but are not supported.

                        _width = _element.offsetWidth
                        _height = _element.offsetHeight

                        if (_constraint is 'min-width' and _width >= value) or (_constraint is 'max-width' and _width <= value) or (_constraint is 'min-height' and _height >= value) or (_constraint is 'max-height' and _height <= value)
                            # Add matching attr value
                            frame_fns.push([ addTo, _element, _constraint, value ])
                        else
                            # Remove non-matching attr value
                            frame_fns.push([ removeFrom, _element, _constraint, value ])

    unless pending_frame
        pending_frame = true
        window.requestAnimationFrame ->
            pending_frame = false
            frame_fns.forEach ([ fn, args... ]) -> fn(args...)

refresh()
window.addEventListener('resize', refresh, false)
window['elementQuery'] = refresh
