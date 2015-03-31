
module.exports = (link, utms...) ->

    utm = {}
    utms = utms.filter (u) -> u?
    unless utms.length > 0
        return link
    utms.forEach (u) ->
        for k,v of u
            if v?
                utm[k] = v
    utm = ("utm_#{ k }=#{ v }" for k,v of utm)

    return "#{ link }?#{ utm.join('&') }"
