// @flow

class EnumerationItem {
    /*::
    item: Object
    index: number
    items: Array<Object>
    next: ?Object
    previous: ?Object
    path: ?(string | Function)
    */
    constructor (kwargs/*: { items: Array<Object>, item: Object, index: number, path: ?(string | Function) }*/) {
        const { items, item, index, path } = kwargs
        this.item       = item
        this.index      = index
        this.items      = items
        this.next       = items.length >= index ? items[index + 1] : null
        this.previous   = items.length >= 0 && index > 0 ? items[index - 1] : null
        this.path       = path
    }

    asIterateeArgs ()/* [?Object, number, EnumerationItem]  */ {
        return [this.item, this.index, this]
    }
}

module.exports = EnumerationItem