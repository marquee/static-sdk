makeRequest = require './makeRequest'

module.exports = (url, callback) ->
    return makeRequest url, (response_text, xhr) ->
        if response_text
            callback(JSON.parse(response_text), xhr)
        else
            callback(null, xhr)
