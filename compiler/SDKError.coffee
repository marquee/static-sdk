

colors  = require 'colors/safe'
util    = require 'util'

colors.setTheme
  silly     : 'rainbow',
  input     : 'grey',
  verbose   : 'cyan',
  prompt    : 'grey',
  info      : 'green',
  data      : 'grey',
  help      : 'cyan',
  warn      : 'yellow',
  debug     : 'blue',
  error     : 'red'


MAIN = 'http://docs.marquee.by/marquee-static-sdk/'

DOCS =
    main            : MAIN
    configuration   : "#{ MAIN }configuration/"
    tokens          : "#{ MAIN }tokens/"
    emitFile        : "#{ MAIN }emitFile/"
    files           : "#{ MAIN }files/"
    api:
        404: "#{ MAIN }api/not-found/"
        401: "#{ MAIN }api/unauthorized/"
        403: "#{ MAIN }api/forbidden/"
        toString: -> "#{ MAIN }api/"




SDKError = (subject, message, code=null) ->
    if arguments.length is 1
        return new Error(colors.error(subject))
    unless DOCS[subject]
        console.warn(colors.warn("Unknown error subject specified: #{ subject }"))
        return new Error(colors.error(message))
    if code and DOCS[subject][code]
        url = DOCS[subject][code]
    else
        url = DOCS[subject]
    return new Error("#{ colors.error(message) } See: #{ colors.underline(colors.help(url)) }\n")



SDKError.warn = (subject, message, code=null) ->
    if arguments.length is 1
        util.log(colors.warn(subject))
        return
    unless DOCS[subject]
        console.warn(colors.warn("Unknown error subject specified: #{ subject }"))
        util.log(colors.warn(message))
        return
    if code and DOCS[subject][code]
        url = DOCS[subject][code]
    else
        url = DOCS[subject]
    return util.log("#{ colors.warn(message) } See: #{ colors.underline(colors.help(url)) }")




SDKError.colors = colors

module.exports = SDKError