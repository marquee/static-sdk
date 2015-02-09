Metric = require './Metric'


module.exports = ->
    seen_metric     = new Metric('Block')
    blocks          = []
    track_timeout   = null


    getPageYPosition = (el) ->
        node = el
        y_pos = 0
        while node.offsetParent?
            y_pos += node.offsetTop
            node = node.offsetParent
        return y_pos


    throttle = (fn, cooldown) ->
        last_called = new Date(0)
        _callFn = (args...) ->
            now = new Date()
            if now - last_called >= cooldown
                last_called = now
                fn(args...)
        return _callFn


    gatherBlocks = ->
        i = 0
        for el in document.querySelectorAll('.Block')
            do ->
                i += 1
                # Some blocks have a ._Content element that has more correct
                # dimensions, eg Image blocks.
                _content_el = el.querySelector('._Content')
                unless _content_el
                    _content_el = el
                blocks.push
                    content_el  : _content_el
                    depth       : i
                    el          : el
                    was_seen    : false


    checkDepth = ->
        visibility_threshold = window.pageYOffset + window.innerHeight

        # The block is visible if its top is above the bottom of the window, and
        # its bottom is below the top of the window.
        _blockIsVisible = (_top, _height) ->
            return _top < visibility_threshold and _top + _height > window.pageYOffset

        blocks.forEach (block, i) ->
            clearTimeout(block.track_timeout)
            _top = getPageYPosition(block.content_el)
            _height = block.content_el.offsetHeight
            if _blockIsVisible(_top, _height) and not block.was_seen
                block.track_timeout = setTimeout ->
                    block.was_seen = true
                    block.el.dataset.seen = true
                    # Track that a block was visible for at least 1000ms
                    # Record the depth in terms of...
                    seen_metric.track
                        type        : 'seen'
                        id          : block.content_el.dataset.content_id
                        # ...block order
                        depth       : block.depth
                        # ...block order as percentage of block count
                        percent     : Number((block.depth / blocks.length).toFixed(2))
                        # ...pixel position on page
                        px_top      : _top
                        # ...pixel position as percentage of page pixels
                        px_percent  : Number((_top / entry_content_el.offsetHeight).toFixed(2))
                        # ...pixel height of block as percentage of page pixels
                        px_portion  : Number((block.content_el.offsetHeight / entry_content_el.offsetHeight).toFixed(2))
                , 2000
    # TODO: window.addEventListener 'copy'

    # TODO: Block.getVisibleBlocks()
    gatherBlocks()
    if blocks.length > 0
        entry_content_el = document.querySelector('.Entry__ ._Content__')
        window.addEventListener('scroll', throttle(checkDepth, 100))
