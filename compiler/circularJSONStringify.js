// @flow

module.exports = function circularJSONStringify (obj/*: Object*/)/*: string */ {
    const cache = new Set()
    return JSON.stringify(obj, (key, value) => {
        if ((typeof value === 'object') && (null !== value)) {
            if (cache.has(value)) {
                // Circular reference found, discard key
                return;
            }
            cache.add(value)
        }
        return value
    })
}