
module.exports = getElPositionAndSize = (el) ->
    node = el
    left = 0
    top = 0
    width = node.offsetWidth
    height = node.offsetHeight
    while node.offsetParent isnt null
        left += node.offsetLeft
        top += node.offsetTop
        node = node.offsetParent
    return { left, top, width, height }