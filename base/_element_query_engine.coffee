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

refresh = ->
    for selector, rules of _query_data
        do ->
            elements = document.querySelectorAll(selector)
            for element in elements
                for constraint, values of rules
                    values.forEach (value) ->

                        # NOTE: Using offsetWidth/Height so an element can be adjusted when it reaches a specific size.
                        # For Nested queries scrollWidth/Height or clientWidth/Height may sometime be desired but are not supported.

                        if (constraint is 'min-width' and element.offsetWidth >= value) or (constraint is 'max-width' and element.offsetWidth <= value) or (constraint is 'min-height' and element.offsetHeight >= value) or (constraint is 'max-height' and element.offsetHeight <= value)
                            # Add matching attr value
                            addTo(element, constraint, value)
                        else
                            # Remove non-matching attr value
                            removeFrom(element, constraint, value)

refresh()
window.addEventListener('resize', refresh, false)
window['elementQuery'] = refresh
