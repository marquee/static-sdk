
DEVICE_PIXEL_RATIO              = window.devicePixelRatio or 1
listenToThrottledWindowEvent    = require '../utils/listenToThrottledWindowEvent'
getElPositionAndSize            = require '../utils/getElPositionAndSize'
Metric                          = require '../Metric'

TRANSITION_DURATION = 500

class ImageZoomer

    active_zoomer = null

    metric = new Metric('ImageZoomer')

    constructor: (el) ->
        @_el = el
        @_buildEl()
        @_bindEvents()

        @_el.dataset.is_zoomed      = false
        @_el.dataset.zoom_enabled   = true
        @_is_transitioning          = false
        @_is_zoomed                 = false

        @_zoom_count                = 0

    _buildEl: ->
        zoomer = document.createElement('div')
        zoomer.className = 'ImageZoomer'
        zoomer_image = document.createElement('img')
        zoomer_image.className = '_Image'
        zoomer.appendChild(zoomer_image)

        @_ui =
            image           : @_el.querySelector('._Image')
            caption         : @_el.querySelector('._Caption')
            zoomer          : zoomer
            zoomer_image    : zoomer_image

        @_ui.image.style.cursor = 'zoom-in'
        @_ui.zoomer.style.cursor = 'zoom-out'
        @_ui.zoomer.dataset.is_zoomed = false

    _bindEvents: ->
        @_ui.image.addEventListener('click', @zoomIn)
        @_ui.zoomer.addEventListener 'click', =>
            @zoomOut(false)

    zoomIn: =>
        if @_is_transitioning or @_is_zoomed
            return

        active_zoomer = this
        @_is_transitioning = true
        aspect_ratio = Number(@_el.dataset.aspect_ratio)
        # position zoomer
        { left, top, width, height } = getElPositionAndSize(@_ui.image)
        top -= window.pageYOffset
        left -= window.pageXOffset

        scale = if aspect_ratio < 1 then window.innerHeight / height else window.innerWidth / width
        @_ui.zoomer_image.style.left                = "#{ left }px"
        @_ui.zoomer_image.style.top                 = "#{ top }px"
        @_ui.zoomer_image.style.position            = 'absolute'
        @_ui.zoomer.style.width                     = "#{ window.innerWidth }px"
        @_ui.zoomer.style.height                    = "#{ window.innerHeight }px"
        @_ui.zoomer.style.left                      = '0px'
        @_ui.zoomer.style.top                       = '0px'
        @_ui.zoomer.style.position                  = 'fixed'
        @_ui.zoomer_image.style.transitionProperty  = 'opacity, transform'
        @_ui.zoomer_image.style.transitionDuration  = "#{ TRANSITION_DURATION }ms"
        @_ui.zoomer_image.style.transform           = "translate3d(0,0,0) scale3d(1,1,1)"
        @_ui.zoomer.style.transitionProperty        = 'background-color'
        @_ui.zoomer.style.transitionDuration        = "#{ TRANSITION_DURATION }ms"
        @_ui.zoomer.style.backgroundColor           = 'rgba(255,255,255,0.0)'

        @_ui.zoomer.dataset.is_zoomed = true
        window_aspect_ratio = window.innerWidth / window.innerHeight
        document.body.appendChild(@_ui.zoomer)
        @_ui.zoomer_image.style.width = "#{ width }px"
        @_ui.zoomer_image.style.height = "#{ height }px"
        @_loadLargeImage aspect_ratio, scale, (selected_size) =>
            @_zoom_count += 1

            if window_aspect_ratio > aspect_ratio
                _scale = window.innerHeight / height
            else
                _scale = window.innerWidth / width
            _top = -1 * top + (window.innerHeight - height) / 2
            _left = -1 * left + (window.innerWidth - width) / 2
            @_ui.zoomer_image.style.transform   = "translate3d(#{ _left }px,#{ _top }px,0) scale3d(#{ _scale },#{ _scale },1)"
            @_ui.zoomer.style.backgroundColor   = 'rgba(255,255,255,0.9)'
            setTimeout =>
                @_is_transitioning = false
                @_is_zoomed = true
            , TRANSITION_DURATION

            selectVariant = (el, variant) ->
                exp = new RegExp("-#{ variant }--([\w\d]+)")
                for class_ in el.classList
                    match = class_.match(exp)
                    if match
                        return match[1]
                return null

            metric.track
                type            : 'zoom_in'
                selected_size   : selected_size
                count           : @_zoom_count
                image:
                    id          : @_el.id
                    size        : selectVariant(@_el, 'size')
                    position    : selectVariant(@_el, 'position')

    zoomOut: (use_opacity=false) =>
        if @_is_transitioning or not @_is_zoomed
            return

        if use_opacity
            @_ui.zoomer_image.style.opacity = 0
        else
            @_ui.zoomer_image.style.transform = 'translate3d(0,0,0) scale3d(1,1,1)'
        @_ui.zoomer.style.backgroundColor = 'rgba(255,255,255,0)'
        setTimeout =>
            @_ui.zoomer.remove()
            active_zoomer = null
            @_is_zoomed = false
            @_ui.zoomer.dataset.is_zoomed       = false
            @_ui.zoomer_image.style.opacity     = 1
            @_ui.zoomer_image.style.transform   = 'translate3d(0,0,0) scale3d(1,1,1)'

            metric.track
                type            : 'zoom_out'
                intiator        : if use_opacity then 'scroll' else 'click'
                image:
                    id: @_el.id

        , TRANSITION_DURATION

    _loadLargeImage: (aspect_ratio, scale, callback) ->
        if @_ui.zoomer_image.src
            setTimeout =>
                @_ui.zoomer_image.style.opacity = 1
                callback()
            , 1
            return 

        @_ui.zoomer_image.style.opacity = 0

        
        if aspect_ratio < 1
            resulting_width = window.innerHeight * DEVICE_PIXEL_RATIO * aspect_ratio
        else
            resulting_width = window.innerWidth * DEVICE_PIXEL_RATIO

        if resulting_width > 1300
            src = @_el.dataset.src_2560
            selected_size = '2560'
            console.info('ImageZoomer: selecting 2560')
        
        if not src and resulting_width > 700
            src = @_el.dataset.src_1280
            selected_size = '1280'
            console.info('ImageZoomer: selecting 1280')

        unless src
            src = @_el.dataset.src_640
            selected_size = '640'
            console.info('ImageZoomer: selecting 640')

        @_ui.zoomer_image.addEventListener 'load', =>
            @_ui.zoomer_image.style.opacity = 1
            setTimeout ->
                callback(selected_size)
            , TRANSITION_DURATION

        @_ui.zoomer_image.src = src

    activated_once = false

    @activate = ->
        unless activated_once
            activated_once = true
            listenToThrottledWindowEvent 'scroll', ->
                active_zoomer?.zoomOut(true)

        els = document.querySelectorAll('[data-zoomable="true"]')
        for el in els
            unless el.dataset.zoom_enabled is 'true'
                new ImageZoomer(el)


module.exports = ImageZoomer
require('./client_modules').register('ImageZoomer', module.exports)