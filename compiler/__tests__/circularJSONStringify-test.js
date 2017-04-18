jest.autoMockOff()

describe('circularJSONStringify', () => {
    let circularJSONStringify

    beforeEach( () => {
        circularJSONStringify = require('../circularJSONStringify')
    })

    it('should stringify a regular object', () => {
        expect(circularJSONStringify({ a: 1 })).toEqual('{"a":1}')
    })

    it('should stringify a circular object', () => {
        const self = { a: 1, c: true, d: {} }
        self.b = self
        self.d.nested = self
        expect(circularJSONStringify(self)).toEqual('{"a":1,"c":true,"d":{}}')
    })
})