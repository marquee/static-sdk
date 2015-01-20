
mime = require 'mime'


AWS     = require 'aws-sdk'

SDKError = require '../compiler/SDKError'

fs = require 'fs'
path = require 'path'


COMPRESSABLE = ['js', 'css', 'svg', 'html', 'txt', 'json', 'xml']

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

        if metadata[rel_path]
            s3_options.Metadata = metadata[rel_path]
            if metadata[rel_path]['Content-Type']?
                s3_options.ContentType = metadata[rel_path]['Content-Type']
            if metadata[rel_path]['content-type']?
                s3_options.ContentType = metadata[rel_path]['content-type']
            if metadata[rel_path]['CONTENT-TYPE']?
                s3_options.ContentType = metadata[rel_path]['CONTENT-TYPE']

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
