module.exports = (link, rts...) ->

    rt = {}
    rts = rts.filter (r) -> r?
    unless rts.length > 0
        return link
    rts.forEach (r) ->
        for k,v of r
            if v?
                rt[k] = v
    rte = encodeURIComponent(
        (
            new Buffer(
                JSON.stringify(rt)
            )
        ).toString('base64')
    )
    return "#{ link }#rt_e=#{ rte }"
