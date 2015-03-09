info = null

# Lazily load and cache the build info inserted into the page by the
# <BuildInfo /> component.
module.exports = ->
    unless info
        info_el = document.getElementById('_build_info')
        if info_el
            try
                info = JSON.parse(info_el.innerHTML)
            catch e
                info = {}
    return info