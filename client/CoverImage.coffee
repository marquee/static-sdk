listenToThrottledWindowEvent = require './utils/listenToThrottledWindowEvent'

init = ->
    px_ratio = window.devicePixelAspectRatio or 1

    image_resize_fns        = []
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
        for el in document.querySelectorAll('.CoverImage')
            unless el.dataset.is_empty is 'true'
                do ->
                    image_block = el
                    image_resize_fns.push ->
                        if image_block.dataset.is_loading is 'true'
                            return

                        if visibilityCheck(image_block)
                            image_block.dataset.is_loading = true
                            if image_block.offsetWidth * px_ratio > 1330 and image_block.dataset.src_2560
                                src = image_block.dataset.src_2560
                                image_block.dataset.selected_size = '2560'
                            else if image_block.offsetWidth * px_ratio > 668
                                src = image_block.dataset.src_1280
                                image_block.dataset.selected_size = '1280'
                            else
                                src = image_block.dataset.src_640
                                image_block.dataset.selected_size = '640'
                            console.info("CoverImage: loading #{ src }")
                            preloader_img = document.createElement('img')
                            preloader_img.src = src
                            preloader_img.onload = ->
                                image_block.style.backgroundImage = "url('#{ src }')"
                                image_block.dataset.loaded = true
                                image_block.dataset.is_loading = false

    renderAllImages = ->
        image_resize_fns.forEach (fn) -> fn()


    gatherImages()
    if image_resize_fns.length > 0
        renderAllImages()
        listenToThrottledWindowEvent('resize', renderAllImages)
        listenToThrottledWindowEvent('scroll', renderAllImages)

module.exports =
    activate: init
require('./client_modules').register('CoverImage', module.exports)
