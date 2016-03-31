
fs = require 'fs'
AWS     = require 'aws-sdk'

SDKError = require '../compiler/SDKError'

getFilesOnS3 = (project_config, callback) ->

    s3 = new AWS.S3
        accessKeyId     : project_config.AWS_ACCESS_KEY_ID
        secretAccessKey : project_config.AWS_SECRET_ACCESS_KEY

    results = []

    _getObjects = (marker) ->

        s3_options =
            Bucket          : project_config.AWS_BUCKET
        if marker
            s3_options.Marker = marker

        s3.listObjects s3_options, (err, data) ->
            throw new SDKError(err) if err?
            results.push(data.Contents...)
            if data.IsTruncated
                _getObjects(data.Contents[data.Contents.length - 1].Key)
            else
                callback(results)
    _getObjects()

crypto = require 'crypto'
getEtagFor = (file) ->
    etag = crypto.createHash('md5')
    etag.update(
            fs.readFileSync(file.local.local_path)
        )
    return etag.digest('hex')


module.exports = (options, build_directory, local_files, project_config, callback) ->
    SDKError.log(SDKError.colors.grey("Finding changed/deleted files..."))

    ignore_prefix_exp = (
        if project_config.IGNORE_PREFIX
            new RegExp("^#{ project_config.IGNORE_PREFIX }/")
        else
            null
    )
    root_prefix_exp = (
        if project_config.ROOT_PREFIX
            new RegExp("^#{ project_config.ROOT_PREFIX }/")
        else
            null
    )

    _isIgnorable = (key) ->
        if ignore_prefix_exp
            return key.match(ignore_prefix_exp)?
        if root_prefix_exp
            return not key.match(root_prefix_exp)?
        return false

    getFilesOnS3 project_config, (remote_files) ->
        local_map = {}
        remote_map = {}
        local_files.forEach (f) ->
            key = f.replace(build_directory, '').substring(1)
            unless _isIgnorable(key)
                local_map[key] = {
                    local_path: f
                    key: key
                }

        unknown = []
        changed = []
        deleted = []
        unchanged = []
        remote_files.forEach (f) ->
            if _isIgnorable(f.Key)
                return

            # Ignore files that don't exist locally when deleting of remote
            # files is disabled.
            if options.no_delete and not local_map[f.Key]
                return

            remote_map[f.Key] = true
            unless local_map[f.Key]?
                # Files that don't exist locally and need to be deleted from
                # the remote deployment.
                deleted.push
                    local: null
                    remote: f
            else
                # Files that exist locally and remotely and need to be checked
                # for sameness.
                unknown.push
                    local: local_map[f.Key]
                    remote: f

        for k,v of local_map
            unless remote_map[k]
                # Files that exist locally but not remotely and definitely need
                # to be uploaded.
                changed.push
                    local: v
                    remote: null

        unknown.forEach (f) ->
            if getEtagFor(f) isnt JSON.parse(f.remote.ETag)
                changed.push(f)
            else
                unchanged.push(f)

        SDKError.log(SDKError.colors.grey("Changed: #{ changed.length }, Deleted: #{ deleted.length }, Unchanged: #{ unchanged.length }"))

        callback
            changed: changed
            deleted: deleted
            unchanged: unchanged

