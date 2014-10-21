
mime = require 'mime'
UglifyJS        = require 'uglify-js'
sqwish          = require 'sqwish'
zlib    = require 'zlib'
AWS     = require 'aws-sdk'

SDKError = require '../compiler/SDKError'

fs = require 'fs'
minifyCSS = (source) ->
    return sqwish.minify(source)

minifyJS = (source) ->
    return UglifyJS.minify(source, fromString: true).code

gzipCompress = (source, cb) ->
    zlib.gzip source, (err, result) ->
        throw err if err?
        cb(result)


COMPRESSABLE = ['js', 'css', 'svg', 'html', 'txt', 'json']

module.exports = (build_directory, files_to_deploy, project_config, callback) ->

    s3 = new AWS.S3
        accessKeyId     : project_config.AWS_ACCESS_KEY_ID
        secretAccessKey : project_config.AWS_SECRET_ACCESS_KEY

    gzipped_total_uploaded = 0
    gzipped_total_pre_upload = 0
    total_uploaded = 0

    to_upload = files_to_deploy.length

    files_to_deploy.forEach (f) ->
        rel_path = f.replace(build_directory + '/','')

        fs.readFile f, (err, file_content) ->
            throw err if err?
            _ext = rel_path.split('.').pop()

            if _ext is 'js'
                file_content = minifyJS(file_content.toString())
            else if _ext is 'css'
                file_content = minifyCSS(file_content.toString())

            s3_options =
                Bucket          : project_config.AWS_BUCKET
                Key             : rel_path
                ACL             : 'public-read'
                ContentType     : mime.lookup(rel_path)
                StorageClass    : 'REDUCED_REDUNDANCY'

            _upload = (body) ->
                gzipped_total_uploaded += body.length if s3_options.ContentEncoding is 'gzip'
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
                        _file_count = SDKError.colors.green("#{ files_to_deploy.length } files, #{ total_uploaded } bytes")
                        SDKError.log("Uploaded #{ _file_count } to #{ SDKError.colors.cyan(project_config.AWS_BUCKET) }")
                        SDKError.log(SDKError.colors.grey("(gzip saved #{ Math.floor((gzipped_total_pre_upload - gzipped_total_uploaded) / gzipped_total_pre_upload * 100) }% on compressable files)"))
                        callback()

            if _ext in COMPRESSABLE
                s3_options.ContentEncoding = 'gzip'
                gzipped_total_pre_upload += file_content.length
                gzipCompress file_content, (compressed) ->
                    _upload(compressed)
            else
                _upload(file_content)
