module.exports = ->
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
        return window.pageYOffset + (window.innerHeight * (1 + VISIBILITY_THRESHOLD)) > y_pos or not window.pageYOffset?


    gatherImages = ->
        for el in document.querySelectorAll('.ImageBlock')
            do ->
                image_block = el
                content_el  = el.querySelector('._Content')
                image_el    = el.querySelector('._Image')
                caption_el  = el.querySelector('._Caption')
                is_pinned   = JSON.parse(el.dataset.pinned)

                image_resize_fns.push ->
                    height = content_el.offsetWidth / image_block.dataset.aspect_ratio

                    height += caption_el?.offsetHeight or 0

                    unless is_pinned
                        content_el.style.height = "#{ height }px"

                    if not image_block.dataset.loaded and visibilityCheck(image_block)
                        if content_el.offsetWidth / px_ratio > 640
                            src = image_block.dataset.src_1280
                        else
                            src = image_block.dataset.src_640
                        console.log("ImageBlock: loading #{ src }")
                        if is_pinned
                            image_el.style.backgroundImage = "url('#{ src }')"
                            image_block.dataset.loaded = true
                        else
                            image_el.src = src
                            image_el.onload = ->
                                image_block.dataset.loaded = true


    renderAllImages = ->
        if not last_called or new Date() - last_called > THROTTLE
            image_resize_fns.forEach (fn) -> fn()
            last_called = new Date()
        return


    gatherImages()
    if image_resize_fns.length > 0
        renderAllImages()
        window.addEventListener('resize', renderAllImages)
        window.addEventListener('scroll', renderAllImages)