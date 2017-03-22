
preloadImage = (url, cb) ->
    img = document.createElement('img')
    img.onload = ->
        cb()
    img.src = url

CLOSE_ICON = """
<svg width="100%" height="100%" viewBox="0 0 65 65" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g class='_Icon' stroke="none" stroke-width="1" fill-rule="evenodd">
        <polygon points="64.7094727 59.4873047 59.4873047 64.7094727 32.3320312 37.5541992 5.17675781 64.7094727 0 59.4873047 27.1552734 32.3320312 0 5.17675781 5.17675781 0 32.3320312 27.1552734 59.4873047 0 64.7094727 5.17675781 37.5541992 32.3320312"></polygon>
    </g>
</svg>
"""

LEFT_ICON = """
<svg width="100%" height="100%" viewBox="0 0 42 71" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g class='_Icon' stroke="none" stroke-width="1" fill-rule="evenodd">
        <polygon transform="translate(20.767434, 35.307617) rotate(-90.000000) translate(-20.767434, -35.307617) " points="-14.5401833 49.818005 20.7376384 14.5401833 56.0750511 49.818005 49.818005 56.0750511 20.7376384 26.9946845 -8.2831372 56.0750511"></polygon>
    </g>
</svg>
"""

RIGHT_ICON = """
<svg width="100%" height="100%" viewBox="0 0 42 71" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g class='_Icon' stroke="none" stroke-width="1" fill-rule="evenodd">
        <polygon transform="translate(20.767434, 35.307617) rotate(-270.000000) translate(-20.767434, -35.307617) " points="-14.5401833 49.818005 20.7376384 14.5401833 56.0750511 49.818005 49.818005 56.0750511 20.7376384 26.9946845 -8.2831372 56.0750511"></polygon>
    </g>
</svg>
"""

renderImageEl = (image) ->
    el = document.createElement('button')
    el.className                = '_GridThumbnail'
    el.style.backgroundColor    = 'transparent'
    el.style.border             = '0'
    el.style.cursor             = 'pointer'
    el.style.display            = 'inline-block'
    el.style.overflow           = 'hidden'
    el.style.padding            = '0'
    el.style.verticalAlign      = 'top'


    image_el = document.createElement('div')
    image_el.className                  = '_GridThumbnailImage'
    image_el.style.backgroundImage      = "url('#{ image.urls['128'] }')"
    image_el.style.backgroundPosition   = 'center center'
    image_el.style.backgroundRepeat     = 'no-repeat'
    image_el.style.backgroundSize       = 'cover'
    image_el.style.filter               = 'blur(1px)'
    image_el.style.height               = '100%'
    image_el.style.transitionDuration   = '0.1s'
    image_el.style.transitionProperty   = '"filter"'
    image_el.style.width                = '100%'

    preloadImage image.urls['640'], ->
        image_el.style.backgroundImage  = "url('#{ image.urls['640'] }')"
        image_el.style.filter           = 'blur(0)'

    el.appendChild(image_el)
    return el

class Lightbox
    IMAGE_SPACING = 10
    BOX_GUTTER = 20

    constructor: (images, inline=false) ->
        @_inline = inline
        @_images = images
        @el = document.createElement('div')
        @el.className       = 'GalleryLightbox'
        
        @el.style.height    = '100vh'
        @el.style.left      = '0'
        @el.style.position  = if inline then 'relative' else 'fixed'
        @el.style.top       = '0'
        @el.style.width     = '100vw'
        @el.style.overflow  = 'hidden'
        @el.style.transitionProperty = 'opacity'
        @el.style.transitionDuration = '0.2s'
        @el.style.backgroundColor = "rgba(0,0,0,0.8)"

        @_buildBox()
        @_buildControls()
        @_current_image_id = 0

        unless @_inline
            @el.style.opacity   = '0'
            @el.style.display   = 'none'
            @el.addEventListener 'click', (e) =>
                @hide()
            document.body.appendChild(@el) 
        else
            window.requestAnimationFrame => @show(0)
            

    _buildControls: ->
        @_previous_button = document.createElement('button')
        @_previous_button.className = '_ControlButton -previous'
        @_previous_button.addEventListener 'click', (e) =>
            e.stopPropagation()
            @_previousImage()
        @_previous_button.setAttribute('aria-label', 'Previous Image')
        @_previous_button.innerHTML = LEFT_ICON
        @_previous_button.style.left = '1px'
        @_previous_button.style.position = 'absolute'
        @_previous_button.style.top = '49vh'
        @el.appendChild(@_previous_button)

        @_next_button = document.createElement('button')
        @_next_button.className = '_ControlButton -next'
        @_next_button.addEventListener 'click', (e) =>
            e.stopPropagation()
            @_nextImage()
        @_next_button.setAttribute('aria-label', 'Next Image')
        @_next_button.innerHTML = RIGHT_ICON
        @_next_button.style.position = 'absolute'
        @_next_button.style.right = '1px'
        @_next_button.style.top = '49vh'
        @el.appendChild(@_next_button)

        unless @_inline
            @_close_button = document.createElement('button')
            @_close_button.className = '_ControlButton -previous'
            @_close_button.addEventListener 'click', (e) =>
                e.stopPropagation()
                @hide()
            @_close_button.setAttribute('aria-label', 'Close Gallery')
            @_close_button.innerHTML = CLOSE_ICON
            @_close_button.style.position = 'absolute'
            @_close_button.style.top = '1px'
            @_close_button.style.right = '1px'
            @el.appendChild(@_close_button)

        
        


    _buildBox: ->
        @_display_row = document.createElement('div')
        @_display_row.className = '_LightboxRow'
        @_display_row.style.height = '100%'
        @_display_row.style.transitionProperty = 'transform'
        @_display_row.style.transitionDuration = '0.5s'
        row_width = 0
        first_width = null
        @_images.forEach (image, i) =>
            image_el = document.createElement('div')
            _height = window.innerHeight - BOX_GUTTER * 2
            _width = Math.floor(image.aspect_ratio * _height)
            if _width > window.innerWidth - BOX_GUTTER * 2
                _width = window.innerWidth - BOX_GUTTER * 2
                _height = Math.floor(_width / image.aspect_ratio)
            row_width += _width + IMAGE_SPACING
            first_width ?= _width
            image_el.className                  = '_LightboxImage'
            image_el.style.backgroundImage      = "url('#{ image.urls['128'] }')"
            image_el.style.backgroundSize       = 'cover'
            image_el.style.height               = "#{ _height }px"
            image_el.style.width                = "#{ _width }px"
            image_el.style.display              = 'inline-block'
            image_el.style.verticalAlign        = 'middle'
            image_el.style.transitionDuration   = '0.1s'
            image_el.style.transitionProperty   = '"filter, transform"'
            image_el.style.filter               = 'blur(3px) grayscale(1)'
            image_el.style.marginRight          = "#{ IMAGE_SPACING }px"
            image_el.style.position             = 'relative'

            if image.caption or image.credit
                caption_el = document.createElement('div')
                caption_el.className        = '_LightboxImageCaption'
                caption_el.style.position   = 'absolute'
                caption_el.style.bottom     = '0'
                caption_el.style.left       = '0'
                caption_el.style.right      = '0'
                caption_el.style.opacity    = '0'
                caption_el.style.transitionDuration   = '0.5s'
                caption_el.style.transitionProperty   = '"opacity"'
                _caption = document.createElement('p')
                _caption.className = '_Caption'
                _caption.textContent = image.caption
                caption_el.appendChild(_caption)
                _credit = document.createElement('p')
                _credit.className = '_Credit'
                _credit.textContent = image.credit
                caption_el.appendChild(_credit)
                image_el.appendChild(caption_el)
                image_el.caption_el = caption_el

            image_el._is_loaded = false
            selected_size = '2560'
            preloadImage image.urls[selected_size], ->
                image_el._is_loaded = true
                image_el.style.backgroundImage = "url('#{ image.urls[selected_size] }')"
                if image_el._is_current
                    image_el.style.filter = 'blur(0) grayscale(0)'
            @_display_row.appendChild(image_el)
            image.lightbox_el = image_el
            image_el.addEventListener 'click', (e) =>
                @_setCurrentImage(i)
                e.stopPropagation()
        @_display_row.style.width = "#{ row_width }px"
        @_display_row.style.marginTop = "#{ IMAGE_SPACING }px"
        @el.appendChild(@_display_row)

    show: (id) ->
        unless @_inline
            document.body.setAttribute('data-lock_scroll', 'true')
            window.addEventListener('keyup', @_hideOnEscape)
            window.addEventListener('keydown', @_navigateOnKeypress)
        window.requestAnimationFrame =>
            @is_showing = true
            window.setTimeout =>
                @_setCurrentImage(id)
            , 40 
            @el.style.display = 'block'
            @el.style.opacity = '1'

    _setCurrentImage: (id) ->
        offset_width = 0
        @_current_image_id = id
        @_images.forEach (image, i) ->
            image.lightbox_el._is_current = i is id
            if image.lightbox_el._is_current
                offset_width += Math.floor(image.lightbox_el.offsetWidth / 2)
                _blur = if image.lightbox_el._is_loaded then '0' else '3px'
                image.lightbox_el.style.filter = "blur(#{ _blur }) grayscale(0)"
                image.lightbox_el.style.transform = 'scale(1)'
                image.lightbox_el.style.cursor = 'default'
                image.lightbox_el.caption_el?.style.opacity = '1'
            else
                if i < id
                    offset_width += image.lightbox_el.offsetWidth + IMAGE_SPACING
                image.lightbox_el.style.filter = 'blur(3px) grayscale(1)'
                image.lightbox_el.style.transform = 'scale(0.9)'
                image.lightbox_el.style.cursor = 'pointer'
                image.lightbox_el.caption_el?.style.opacity = '0'
        @_next_button.disabled = @_current_image_id is @_images.length - 1
        @_previous_button.disabled = @_current_image_id is 0
        @_display_row.style.transform = "translateX(#{ window.innerWidth / 2 - offset_width }px)"

    _hideOnEscape: (e) =>
        if 27 is e.which
            @hide()

    hide: ->
        unless @_inline
            @el.style.display = 'none'
            # This won't visibly transition but that's okay.
            @el.style.opacity = '0'
            @is_showing = false
            document.body.setAttribute('data-lock_scroll', 'false')
            window.removeEventListener('keyup', @_hideOnEscape)
            window.removeEventListener('keydown', @_navigateOnKeypress)

    _nextImage: =>
        if @_current_image_id < @_images.length - 1
            @_setCurrentImage(@_current_image_id + 1)

    _previousImage: =>
        if @_current_image_id > 0
            @_setCurrentImage(@_current_image_id - 1)


    _navigateOnKeypress: (e) =>
        switch e.which
            when 39 # right arrow
                @_nextImage()
            when 37 # left arrow
                @_previousImage()

class GalleryBlock

    constructor: (el, options) ->
        @_options = options
        @el = el
        try
            @_images = JSON.parse(el.dataset.images)
        catch e
            console.error(e)
            return

        @_images.filter(
            (img) -> img.aspect_ratio? and img.aspect_ratio
        ).forEach (image, i) =>
            image.id = i
            image.width = Math.floor(image.aspect_ratio * @_options.grid_row_height)

        if el.dataset.inline is 'true'
            @el.appendChild(
                (new Lightbox(this._images, true)).el
            )
            return

        @_buildGrid()
        @_renderSizes(@_content_el.offsetWidth)

        pending_frame = false
        window.addEventListener 'resize', =>
            new_width = @_content_el.offsetWidth
            unless pending_frame
                pending_frame = true
                window.requestAnimationFrame =>
                    @_renderSizes(new_width)
                    pending_frame = false

    _buildGrid: ->
        @_content_el = document.createElement('div')
        @_content_el.className = '_Content'
        @_images.forEach (image) =>
            image.el = renderImageEl(image)
            @_content_el.appendChild(image.el)
            image.el.addEventListener 'click', =>
                @_showLightbox(image.id)
        @el.appendChild(@_content_el)

    _showLightbox: (id) =>
        @_lightbox ?= new Lightbox(this._images)
        @_lightbox.show(id)


    _renderSizes: (target_width) ->
        MAX_STRETCH = 50

        rows = []
        current_row = []
        current_row.width = 0

        @_images.forEach (image, i) =>
            if current_row.width + image.width + MAX_STRETCH < target_width
                current_row.push(image)
                current_row.width += image.width
            
            if i is @_images.length - 1 or current_row.width + @_images[i + 1].width + MAX_STRETCH >= target_width
                rows.push(current_row)
                current_row = []
                current_row.width = 0
        
        _height_px = "#{ @_options.grid_row_height }px"
        rows.forEach (row, i) =>

            delta = target_width - row.width
            rendered_width = 0
            per_image_adjustment = Math.floor(delta / row.length)
            if i is rows.length - 1 and per_image_adjustment > MAX_STRETCH
                per_image_adjustment = 0
            row.forEach (image, j) =>
                rendered_width += image.width + per_image_adjustment
                if j is 0
                    image.el.style.marginLeft = "#{ @_options.grid_padding }px"
                else
                    image.el.style.marginLeft = "#{ @_options.grid_padding / 2 }px"
                if j is row.length - 1
                    image.el.style.marginRight = "#{ @_options.grid_padding }px"
                else
                    image.el.style.marginRight = "#{ @_options.grid_padding / 2 }px"

                if j is row.length - 1 and rendered_width < target_width
                    rounding_fix = target_width - rendered_width
                    if rounding_fix + per_image_adjustment > MAX_STRETCH
                        rounding_fix = 0
                else
                    rounding_fix = 0
                image.el.style.height = _height_px
                image.el.style.width = "#{ image.width + per_image_adjustment + rounding_fix - @_options.grid_padding * (row.length + 1) / row.length }px"
                image.el.dataset.row = i
                image.el.dataset.col = j
                image.el.style.marginBottom = "#{ @_options.grid_padding }px"

    @activate = (options)->
        _options = { grid_row_height: 200, grid_padding: 8 }
        _options[k] = v for k,v of options
        for el in document.querySelectorAll('.GalleryBlock[data-images]')
            new GalleryBlock(el, _options)


module.exports = GalleryBlock
require('../client_modules').register('GalleryBlock', module.exports)