listenToThrottledWindowEvent = require './utils/listenToThrottledWindowEvent'

image_resize_fns        = []
VISIBILITY_THRESHOLD    = 0.5 # multiple of window height to be within

_is_bound = false

visibilityCheck = (image_block) ->
    node = image_block
    y_pos = 0
    while node.offsetParent?
        y_pos += node.offsetTop
        node = node.offsetParent
    return window.pageYOffset + (
            window.innerHeight * (1 + VISIBILITY_THRESHOLD)
        ) > y_pos or not window.pageYOffset?

renderAllImages = ->
    image_resize_fns.forEach (fn) -> fn()

gatherImages = ->
    px_ratio = window.devicePixelAspectRatio or 1
    for el in document.querySelectorAll('.CoverImage')
        unless el.dataset.is_empty is 'true' or el.dataset.is_bound
            do ->
                image_block = el
                image_block.dataset.is_bound = true
                image_resize_fns.push ->
                    if image_block.dataset.is_loading is 'true' or image_block.dataset.loaded is 'true'
                        return

                    if visibilityCheck(image_block)
                        image_block.dataset.is_loading = true
                        if image_block.offsetWidth / image_block.offsetHeight > 1
                            comparison_dimension = image_block.offsetWidth
                        else
                            comparison_dimension = image_block.offsetHeight
                        comparison_dimension = comparison_dimension * px_ratio
                        if comparison_dimension > 1330 and image_block.dataset.src_2560
                            src = image_block.dataset.src_2560
                            image_block.dataset.selected_size = '2560'
                        else if comparison_dimension > 668
                            src = image_block.dataset.src_1280
                            image_block.dataset.selected_size = '1280'
                        else
                            src = image_block.dataset.src_640
                            image_block.dataset.selected_size = '640'
                        console.info("CoverImage: loading #{ src }") if window.DEBUG
                        preloader_img = document.createElement('img')
                        preloader_img.src = src
                        preloader_img.onload = ->
                            image_block.querySelector('._Image').style.backgroundImage = "url('#{ src }')"
                            image_block.dataset.loaded = true
                            image_block.dataset.is_loading = false


init = ->

    gatherImages()
    if image_resize_fns.length > 0
        renderAllImages()
        unless _is_bound
            _is_bound = true
            listenToThrottledWindowEvent('resize', renderAllImages)
            listenToThrottledWindowEvent('scroll', renderAllImages)

module.exports =
    activate: init
require('./client_modules').register('CoverImage', module.exports)
