module.exports = (url, callback) ->
    xhr = new XMLHttpRequest()
    xhr.onload = ->
        if xhr.status in [200, 304]
            callback(xhr.responseText, xhr)
        else
            callback(null, xhr)
    xhr.open('get', url)
    xhr.send()
    return xhr