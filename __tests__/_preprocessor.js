// _preprocessor.js
var coffee = require('coffee-script');
var coffeereact = require('coffee-react');

module.exports = {
    process: function(src, path) {
        if (path.match(/\.coffee$/)) {
            return coffee.compile(src, {bare: true});
        }
        if (path.match(/\.cjsx$/)) {
            return coffeereact.compile(src, {bare: true});
        }
        return src;
    }
};
