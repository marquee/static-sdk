module.exports = ->
    openShareWindow = (share_link) ->
        options =
            scrollbars  : 'yes'
            resizable   : 'yes'
            toolbar     : 'no'
            location    : 'yes'
            width       : 550
            height      : 420
        window_options = []
        for k,v of options
            window_options.push("#{ k }=#{ v }")
        window_options = window_options.join(',')
        window.open(share_link, 'intent', window_options)

    share_widgets = document.querySelectorAll('.ShareEntry')
    for w in share_widgets
        do ->
            widget = w
            services = widget.querySelectorAll('._ShareLink')

            for s in services
                do ->
                    service = s

                    service.addEventListener 'blur', (event) ->
                        unless event.relatedTarget in services
                            widget.dataset.open = false

                    service.addEventListener 'focus', ->
                        widget.dataset.open = true

                    service.addEventListener 'click', (e) ->
                        if JSON.parse(service.dataset.popup)
                            e.preventDefault()
                            openShareWindow(service.href)
