// @flow

class EnumerationItem {
    /*::
    item: Object
    index: number
    items: Array<Object>
    next: ?Object
    previous: ?Object
    */
    constructor (kwargs/*: { items: Array<Object>, item: Object, index: number }*/) {
        const { items, item, index } = kwargs
        this.item       = item
        this.index      = index
        this.items      = items
        this.next       = items.length >= index ? items[index + 1] : null
        this.previous   = items.length >= 0 && index > 0 ? items[index - 1] : null
    }

    asIterateeArgs ()/* [?Object, number, EnumerationItem]  */ {
        return [this.item, this.index, this]
    }
}

module.exports = EnumerationItem