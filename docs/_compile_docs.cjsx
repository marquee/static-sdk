
React = require 'react'
path = require 'path'
fs = require 'fs-extra'
marked = require 'marked'

pkg = require '../package.json'
AWS     = require 'aws-sdk'
mime = require 'mime'
for_deploy = '--production' in process.argv

source_directory = __dirname
build_directory = __dirname

project_directory = path.join(__dirname, '..')
asset_source_dir = asset_cache_dir = asset_dest_dir = path.join(__dirname, '_assets')

if for_deploy
    build_directory = path.join(build_directory, '.build')
    if fs.existsSync(build_directory)
        fs.removeSync(build_directory)
    fs.mkdirSync(build_directory)
    deploy_config_path = path.join(__dirname, '.env.json')
    unless fs.existsSync(deploy_config_path)
        throw new Error('You need a .env.json with the necessary config.')
    deploy_config = JSON.parse(fs.readFileSync(deploy_config_path).toString())
    global.ASSET_URL = '/_assets/'
else
    global.ASSET_URL = './_assets/'


_writeFile = require('../compiler/writeFile')(build_directory)
_emitFile = require('../compiler/emitFile')(
    project_directory   : project_directory
    project             : {}
    config              : {}
    writeFile           : _writeFile
)

{ processAsset } = require '../compiler/compileAssets'
getCurrentCommit = require '../compiler/getCurrentCommit'
putFilesToS3 = require '../deployment/putFilesToS3'
walkSync = require '../compiler/walkSync'

{ Gauges } = require '../base/analytics'
{ BuildInfo, makeMetaTags, Asset, Favicon, GoogleFonts } = require '../base'

console.log 'Compiling docs in', build_directory, for_deploy

global.config =
    PUBLICATION_SHORT_NAME: 'marquee-static-sdk'

MarqueeBranding = require '../components/MarqueeBranding'

Base = React.createClass
    render: ->
        <html>
            <head>
                <title>{ if @props.title then "#{ @props.title } - " else null }Marquee Static SDK</title>
                <meta charSet='utf-8' />
                <meta name='viewport' content='width=device-width, initial-scale=1, minimum-scale=1.0' />

                {makeMetaTags(@props.meta)}

                <Asset path='style.sass' inline=true />
                <GoogleFonts fonts={
                    'Open+Sans': ['400italic', '400', '600italic', '600']
                }/>
                <Favicon />
                {@props.extra_head}

            </head>
            <body className='Site__'>

                {@props.children}

                {@props.extra_body}

                <Gauges id=deploy_config.GAUGES_ID />
                <BuildInfo />
            </body>
        </html>


# http://tools.ietf.org/html/rfc2119
RFC2119_KEYWORD_DEFINITIONS =
    MUST: """
        The definition is an absolute requirement of the specification.
    """
    MUST_NOT: """
        The definition is an absolute prohibition of the specification.
    """
    SHOULD: """
        There may exist valid reasons in particular circumstances to ignore a particular item, but the full implications must be understood and carefully weighed before choosing a different course.
    """
    SHOULD_NOT: """
        There may exist valid reasons in particular circumstances when the particular behavior is acceptable or even useful, but the full implications should be understood and the case carefully weighed before implementing any behavior described with this label.
    """
    MAY: """
        The item is truly optional.  One vendor may choose to include the item because a particular marketplace requires it or because the vendor feels that it enhances the product while another vendor may omit the same item. An implementation which does not include a particular option MUST be prepared to interoperate with another implementation which does include the option, though perhaps with reduced functionality. In the same vein an implementation which does include a particular option MUST be prepared to interoperate with another implementation which does not include the option (except, of course, for the feature the option provides.)
    """

RFC2119_KEYWORDS =
    'MUST':
        definition  : RFC2119_KEYWORD_DEFINITIONS.MUST
        regex       : new RegExp('MUST(?! NOT)', 'g')
    'REQUIRED':
        definition  : RFC2119_KEYWORD_DEFINITIONS.MUST
        regex       : new RegExp('REQUIRED', 'g')
    'SHALL':
        definition  : RFC2119_KEYWORD_DEFINITIONS.MUST
        regex       : new RegExp('SHALL(?! NOT)', 'g')
    'MUST NOT':
        definition  : RFC2119_KEYWORD_DEFINITIONS.MUST_NOT
        regex       : new RegExp('MUST NOT', 'g')
    'SHALL NOT':
        definition  : RFC2119_KEYWORD_DEFINITIONS.MUST_NOT
        regex       : new RegExp('SHALL NOT', 'g')
    'SHOULD':
        definition  : RFC2119_KEYWORD_DEFINITIONS.SHOULD
        regex       : new RegExp('SHOULD(?! NOT)', 'g')
    'RECOMMENDED':
        definition  : RFC2119_KEYWORD_DEFINITIONS.SHOULD
        regex       : new RegExp('RECOMMENDED', 'g')
    'SHOULD NOT':
        definition  : RFC2119_KEYWORD_DEFINITIONS.SHOULD_NOT
        regex       : new RegExp('SHOULD NOT', 'g')
    'MAY':
        definition  : RFC2119_KEYWORD_DEFINITIONS.MAY
        regex       : new RegExp('MAY', 'g')
    'OPTIONAL':
        definition  : RFC2119_KEYWORD_DEFINITIONS.MAY
        regex       : new RegExp('OPTIONAL', 'g')

SpecKeyword = React.createClass
    render: ->
        <em
            className   = 'SpecKeyword'
            data-word   = @props.word
            title       = RFC2119_KEYWORDS[@props.word].definition
            style       = { cursor: 'help' }
        >{ @props.word }</em>

ReactDOMServer = require 'react-dom/server'

MarkdownPage = React.createClass
    render: ->
        output_content = fs.readFileSync(@props.file).toString()

        for word, spec of RFC2119_KEYWORDS
            output_content = output_content.replace(
                spec.regex,
                ReactDOMServer.renderToStaticMarkup(
                    <SpecKeyword word=word />
                )
            )
        output_content = marked(output_content)
        <div className='Page__' dangerouslySetInnerHTML={ __html: output_content } />

slugify = (text) ->
    return text.toLowerCase().replace(/\s/g, '-')

Nav = React.createClass
    render: ->
        nav_links = @props.files.map (f) =>
            _title = f.replace(/\.md$/,'')
            _slug = slugify(_title)
            if for_deploy
                link = "/#{ deploy_config.PREFIX }/"
                unless _slug is 'index'
                    link += "#{ _slug }/"
            else
                link = "./#{ _slug }.html"
            if _slug is 'index'
                _title = <span>
                        <span>Marquee Static SDK</span>
                        <span className='_Version'>{pkg.version}</span>
                    </span>
            _current = if f is @props.current then '-current' else ''
            return <a className="_Link #{ _current }" href=link key=_slug>{_title}</a>
        <nav className='Nav'>
            {nav_links}
            <MarqueeBranding campaign='docs' text=false />
        </nav>

getCurrentCommit project_directory, (commit_sha) ->
    processAsset
        asset_source_dir    : asset_source_dir
        asset_cache_dir     : asset_cache_dir
        asset_dest_dir      : asset_dest_dir
        asset               : path.join(asset_source_dir, 'style.sass')
        project_directory   : project_directory
        callback: ->

            global.build_info =
                project_directory       : project_directory
                commit                  : commit_sha
                date                    : new Date()
                build_directory         : build_directory
                asset_cache_directory   : asset_cache_dir

            doc_files = fs.readdirSync(source_directory).filter (f) ->
                f.split('.').pop() is 'md' and f isnt 'index.md'
            doc_files.unshift('index.md')
            doc_files.forEach (f) ->
                title = f.replace(/\.md$/, '')
                slug = slugify(title)
                if for_deploy and f isnt 'index.md'
                    output_name = slug
                else
                    output_name = "#{ slug }.html"

                if f is 'index.md'
                    title = "Marquee Static SDK, v#{ pkg.version }"

                if for_deploy and deploy_config.PREFIX
                    output_name = path.join(deploy_config.PREFIX, output_name)
                _emitFile(
                    output_name,
                    <Base title=title>
                        <div className='_Nav__'>
                            <Nav files=doc_files current=f />
                        </div>
                        <div className='_Content__'>
                            <MarkdownPage file={path.join(source_directory, f)} />
                        </div>
                    </Base>
                )

            if for_deploy
                s3 = new AWS.S3
                    accessKeyId     : deploy_config.AWS_ACCESS_KEY_ID
                    secretAccessKey : deploy_config.AWS_SECRET_ACCESS_KEY

                walkSync(build_directory).forEach (file) ->
                    s3_options =
                        Bucket          : deploy_config.AWS_BUCKET
                        Key             : file.replace(build_directory + '/', '')
                        ACL             : 'public-read'
                        ContentType     : mime.lookup(file)
                        StorageClass    : 'REDUCED_REDUNDANCY'
                        Body            : fs.readFileSync(file)
                    console.log '\tUploading', s3_options.Key
                    s3.putObject s3_options, (err, data) ->
                        throw err if err
