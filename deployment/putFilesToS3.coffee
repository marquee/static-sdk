
mime = require 'mime'


AWS     = require 'aws-sdk'

SDKError = require '../compiler/SDKError'

fs = require 'fs'
path = require 'path'


COMPRESSABLE = ['js', 'css', 'svg', 'html', 'txt', 'json', 'xml']

DEFAULT_CACHE_CONTROLS =
    'html'  : 'max-age=1800' # 30 min
    'json'  : 'max-age=3600' # 60 min
    # These are served under a content-based hash so they should be cached indefinitely.
    'js'    : 'max-age=31536000' # one year (typical valid max)
    'css'   : 'max-age=31536000' # one year
    'jpg'   : 'max-age=31536000' # one year
    'png'   : 'max-age=31536000' # one year
    'ico'   : 'max-age=31536000' # one year


module.exports = (build_directory, files_to_deploy, project_config, callback) ->
    if files_to_deploy.changed.length is 0
        callback()
        return

    s3 = new AWS.S3
        accessKeyId     : project_config.AWS_ACCESS_KEY_ID
        secretAccessKey : project_config.AWS_SECRET_ACCESS_KEY

    total_uploaded = 0

    to_upload = files_to_deploy.changed.length

    metadata = JSON.parse(
            fs.readFileSync(
                    path.join(build_directory, '.metadata.json')
                ).toString()
        )

    # Sort files by reverse "depth". This helps ensure that entries get
    # uploaded before links to them are (ie the homepage).
    files_to_deploy.changed.sort (a,b) ->
        b.local.local_path.split('/').length - a.local.local_path.split('/').length

    files_to_deploy.changed.forEach (f) ->
        rel_path = f.local.local_path.replace(build_directory + '/','')

        # Read the file synchronously. Async results in too many open files.
        file_content = fs.readFileSync(f.local.local_path)
        _ext = rel_path.split('.').pop()

        s3_options =
            Bucket          : project_config.AWS_BUCKET
            Key             : rel_path
            ACL             : 'public-read'
            ContentType     : mime.lookup(rel_path)
            StorageClass    : 'REDUCED_REDUNDANCY'

        # Apply per-extension project-configured CacheControl values.
        if project_config.cache_control?[_ext]
            s3_options.CacheControl = project_config.cache_control[_ext]
        # Apply per-extension default CacheControl values.
        else if DEFAULT_CACHE_CONTROLS[_ext]
            s3_options.CacheControl = DEFAULT_CACHE_CONTROLS[_ext]

        # Apply per-file metadata.
        if metadata[rel_path]
            s3_options.Metadata = metadata[rel_path]
            for k,v of metadata[rel_path]
                # ContentType and CacheControl can be overridden.
                if k.toLowerCase() is 'content-type'
                    s3_options.ContentType = v
                else if k.toLowerCase() is 'cache-control'
                    s3_options.CacheControl = v
                # Other metadata gets scoped under Metadata.
                else
                    s3_options.Metadata ?= {}
                    s3_options.Metadata[k] = v

        _upload = (body) ->
            total_uploaded += body.length
            s3_options.Body = body
            _file_size = SDKError.colors.grey("(#{ body.length } bytes, #{ s3_options.ContentType })")
            SDKError.log("Uploading #{ SDKError.colors.cyan(rel_path) }... #{ _file_size }")
            # Put the compressed page HTML at the target S3 key.
            s3.putObject s3_options, (err, data) ->
                to_upload -= 1
                if err?
                    throw new SDKError('deploy.s3', err)
                else
                    SDKError.log("Saved #{ SDKError.colors.green(rel_path) }.")

                if to_upload is 0
                    _file_count = SDKError.colors.green("#{ files_to_deploy.changed.length } files, #{ total_uploaded } bytes")
                    SDKError.log("Uploaded #{ _file_count } to #{ SDKError.colors.cyan(project_config.AWS_BUCKET) }")
                    callback()

        if _ext in COMPRESSABLE
            s3_options.ContentEncoding = 'gzip'
        _upload(file_content)
