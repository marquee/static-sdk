Metric = require '../Metric'

getElPositionAndSize            = require '../utils/getElPositionAndSize'
listenToThrottledWindowEvent    = require '../utils/listenToThrottledWindowEvent'

module.exports = (content_container='.Entry__ ._Content__') ->
    seen_metric     = new Metric('Block')
    blocks          = []
    track_timeout   = null

    num_seen        = 0

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
            _top = getElPositionAndSize(block.content_el).top
            _height = block.content_el.offsetHeight
            if _blockIsVisible(_top, _height) and not block.was_seen
                block.track_timeout = setTimeout ->
                    block.was_seen = true
                    block.el.dataset.seen = true
                    num_seen += 1
                    # Track that a block was visible for at least 2000ms
                    # Record the depth in terms of...
                    seen_metric.track
                        type            : 'seen'
                        id              : block.content_el.dataset.content_id
                        # ...block order
                        depth           : block.depth
                        # ...block order as percentage of block count
                        depth_percent   : Number((block.depth / blocks.length).toFixed(2))
                        # ...percentage of all blocks seen
                        seen_percent    : Number((num_seen / blocks.length).toFixed(2))
                        # ...pixel position on page
                        top_px          : _top
                        # ...pixel position as percentage of content pixels
                        top_percent     : Number((_top / entry_content_el.offsetHeight).toFixed(2))
                        # ...pixel height of block as percentage of page pixels
                        px_portion      : Number((block.content_el.offsetHeight / entry_content_el.offsetHeight).toFixed(2))
                , 2000

    gatherBlocks()
    if blocks.length > 0
        entry_content_el = document.querySelector(content_container)
        listenToThrottledWindowEvent('scroll', checkDepth)
