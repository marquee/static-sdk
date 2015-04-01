listenToThrottledWindowEvent = require '../utils/listenToThrottledWindowEvent'

init = ->
    px_ratio = window.devicePixelAspectRatio or 1

    last_called             = null
    image_resize_fns        = []
    THROTTLE                = 100 # ms
    VISIBILITY_THRESHOLD    = 0.5 # multiple of window height to be within


    visibilityCheck = (image_block) ->
        node = image_block
        y_pos = 0
        while node.offsetParent?
            y_pos += node.offsetTop
            node = node.offsetParent
        return window.pageYOffset + (
                window.innerHeight * (1 + VISIBILITY_THRESHOLD)
            ) > y_pos or not window.pageYOffset?


    gatherImages = ->
        for el in document.querySelectorAll('.ImageBlock')
            do ->
                image_block = el
                content_el  = el.querySelector('._Content')
                image_el    = el.querySelector('._Image')
                caption_el  = el.querySelector('._Caption')
                is_pinned   = JSON.parse(el.dataset.pinned)

                image_resize_fns.push ->
                    if image_block.datset.is_loading is 'true'
                        return

                    height = content_el.offsetWidth / image_block.dataset.aspect_ratio

                    height += caption_el?.offsetHeight or 0

                    unless is_pinned
                        content_el.style.height = "#{ height }px"
                    else if window.innerWidth < 1024
                        image_el.style.height = "#{ height }px"
                    else
                        image_el.style.height = "100vh"

                    if not image_block.dataset.loaded and visibilityCheck(image_block)
                        image_block.datset.is_loading = true
                        if content_el.offsetWidth * px_ratio > 1330 and image_block.dataset.src_2560
                            src = image_block.dataset.src_2560
                        else if content_el.offsetWidth * px_ratio > 668
                            src = image_block.dataset.src_1280
                        else
                            src = image_block.dataset.src_640
                        console.info("ImageBlock: loading #{ src }")
                        if is_pinned
                            image_el.style.backgroundImage = "url('#{ src }')"
                            image_block.dataset.loaded = true
                            image_block.datset.is_loading = false
                        else
                            image_el.src = src
                            image_el.onload = ->
                                image_block.dataset.loaded = true
                                image_block.datset.is_loading = false


    renderAllImages = ->
        if not last_called or new Date() - last_called > THROTTLE
            image_resize_fns.forEach (fn) -> fn()
            last_called = new Date()
        return


    gatherImages()
    if image_resize_fns.length > 0
        renderAllImages()
        listenToThrottledWindowEvent('resize', renderAllImages)
        listenToThrottledWindowEvent('scroll', renderAllImages)

module.exports =
    activate: init
require('../client_modules').register('ImageBlock', module.exports)