
const path    = require('path')
const colors  = require('colors/safe')
const util    = require('util')

colors.setTheme({
    silly     : 'rainbow',
    input     : 'grey',
    verbose   : 'cyan',
    prompt    : 'grey',
    info      : 'green',
    data      : 'grey',
    help      : 'cyan',
    warn      : 'yellow',
    debug     : 'blue',
    error     : 'red',
})


const MAIN = 'https://developer.proof.pub/sdk/'



const DOCS = {
    main                    : 'compiler/#main',
    configuration           : 'configuration/',
    'configuration.deploy'  : 'configuration/#deployment',
    tokens                  : 'configuration/#tokens',
    emitFile                : 'compiler/#-emitfile-',
    'emitFile.json'         : 'compiler/#-emitfile-',
    'emitFile.path'         : 'compiler/#-emitfile-',
    'project.react'         : 'compiler/#-referenceerror-react-is-not-defined-',
    files                   : '',
    'build-cache.dirty'     : 'compiler/',
    'build-cache.develop'   : 'compiler/',
    assets                  : 'assets/',
    'assets.emitAssets'     : 'assets/#-emitassets-',
    compiler                : 'compiler/',
    'deploy.repo'           : 'compiler/#uncommitted-changes-detected-but-no-changes-apparent',
    api: {
        201: 'api/#201-created',
        204: 'api/#204-no-content',
        404: 'api/#404-not-found',
        401: 'api/#401-unauthorized',
        403: 'api/#403-forbidden',
        410: 'api/#410-gone',
        500: 'api/#500-internal-server-error',
        toString: () => ('api/'),
    }
}

for (let k in DOCS) {
    const v = DOCS[k]
    if (typeof v === 'object') {
        for (let _k in v) {
            if (_k !== 'toString') {
                v[_k] = `${ MAIN }${ v[_k] }`
            }
        }
    } else {
        if (k !== 'toString') {
            DOCS[k] = `${ MAIN }${ v }`
        }
    }
}

SDKError = (subject, message, code=null) => {
    if (1 === arguments.length) {
        return new Error(_prefix + colors.error(subject))
    }
    if (!DOCS[subject]) {
        console.warn(colors.grey(`Unknown error subject specified: ${ subject }`))
        return new Error(_prefix + colors.error(message))
    }
    let url
    if (code && DOCS[subject][code]) {
        url = DOCS[subject][code]
    } else {
        url = DOCS[subject]
    }

    let post_message
    if (message.stack) {
        post_message = `\nOriginal stack trace:\n${ colors.yellow(message.stack) }\n`
    } else {
        post_message = ''
    }
    return new Error(`${ _prefix }${ colors.error(message) }\nDocs: ${ colors.underline(colors.help(url)) }\n${ post_message }`)
}


SDKError.warn = (subject, message, code=null) => {
    if (1 === arguments.length) {
        util.log(_prefix + colors.warn(subject))
        return
    }
    if (!DOCS[subject]) {
        console.warn(colors.warn(`Unknown error subject specified: ${ subject }`))
        util.log(_prefix + colors.warn(message))
        return
    }
    let url
    if (code && DOCS[subject][code]) {
        url = DOCS[subject][code]
    } else {
        url = DOCS[subject]
    }
    return util.log(`${ _prefix }${ colors.warn(message) } Docs: ${ colors.underline(colors.help(url)) }`)
}

SDKError.throw = (subject, message, code=null) => {
    let url
    if (code && DOCS[subject][code]) {
        url = DOCS[subject][code]
    } else {
        url = DOCS[subject]
    }
    util.log(`${ _prefix }${ colors.error(message) } Docs: ${ colors.underline(colors.help(url)) }`)
    process.exit(0)
}

SDKError.formatProjectPath = (p, f=null) => {
    const p_parent = path.dirname(p) + '/'
    if (f) {
        return `${ colors.grey.underline(p.replace(p_parent,'')) }${ colors.green(f.replace(p,'')) }`
    }
    return `${ colors.grey(p_parent) }${ colors.green(p.replace(p_parent,'')) }`
}

let _prefix = ''
SDKError.setPrefix = (prefix) => _prefix = prefix
SDKError.clearPrefix = () => _prefix = ''
SDKError.indent = () => _prefix = '\t'
SDKError.unindent = () => SDKError.clearPrefix()

SDKError.alwaysLog = (message) => {
    util.log(`${ _prefix }${ message }`)
}

SDKError.log = (message) => {
    if (global.VERBOSE) {
        util.log(`${ _prefix }${ message }`)
    }
}

SDKError.colors = colors

module.exports = SDKError