
path    = require 'path'
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
    'emitFile.json' : ''
    'project.react' : ''
    files           : "#{ MAIN }files/"
    assets          : "#{ MAIN }assets/"
    compiler        : "#{ MAIN }compiler/"
    api:
        404: "#{ MAIN }api/not-found/"
        401: "#{ MAIN }api/unauthorized/"
        403: "#{ MAIN }api/forbidden/"
        toString: -> "#{ MAIN }api/"


SDKError = (subject, message, code=null) ->
    if arguments.length is 1
        return new Error(_prefix + colors.error(subject))
    unless DOCS[subject]
        console.warn(colors.warn("Unknown error subject specified: #{ subject }"))
        return new Error(_prefix + colors.error(message))
    if code and DOCS[subject][code]
        url = DOCS[subject][code]
    else
        url = DOCS[subject]

    if message.stack
        post_message = "\nOriginal stack trace:\n#{ colors.yellow(message.stack) }\n"
    else
        post_message = ''
    return new Error("#{ _prefix }#{ colors.error(message) } See: #{ colors.underline(colors.help(url)) }\n#{ post_message }")



SDKError.warn = (subject, message, code=null) ->
    if arguments.length is 1
        util.log(_prefix + colors.warn(subject))
        return
    unless DOCS[subject]
        console.warn(colors.warn("Unknown error subject specified: #{ subject }"))
        util.log(_prefix + colors.warn(message))
        return
    if code and DOCS[subject][code]
        url = DOCS[subject][code]
    else
        url = DOCS[subject]
    return util.log("#{ _prefix }#{ colors.warn(message) } See: #{ colors.underline(colors.help(url)) }")

SDKError.formatProjectPath = (p, f=null) ->
    p_parent = path.dirname(p) + '/'
    if f
        return "#{ colors.grey(p_parent) }#{ colors.grey.underline(p.replace(p_parent,'')) }#{ colors.green(f.replace(p,'')) }"
    return "#{ colors.grey(p_parent) }#{ colors.green(p.replace(p_parent,'')) }"

_prefix = ''
SDKError.setPrefix = (prefix) -> _prefix = prefix
SDKError.clearPrefix = -> _prefix = ''
SDKError.indent = -> _prefix = '\t'
SDKError.unindent = -> SDKError.clearPrefix()

SDKError.log = (message) ->
    util.log("#{ _prefix }#{ message }")

SDKError.colors = colors

module.exports = SDKError