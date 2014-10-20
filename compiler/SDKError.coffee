

colors = require 'colors/safe'

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


MAIN = 'http://docs.marquee.by/sdk/'

DOCS =
    main            : MAIN
    configuration   : "#{ MAIN }configuration/"
    tokens          : "#{ MAIN }tokens/"
    emitFile        : "#{ MAIN }emitFile/"
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

SDKError.colors = colors
module.exports = SDKError