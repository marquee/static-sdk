
AWS     = require 'aws-sdk'

SDKError = require '../compiler/SDKError'

runBatches = (batches, project_config, callback) ->

    s3 = new AWS.S3
        accessKeyId     : project_config.AWS_ACCESS_KEY_ID
        secretAccessKey : project_config.AWS_SECRET_ACCESS_KEY

    _startBatch = ->
        batch = batches.shift()
        if batch
            keys = batch.map (f) -> { Key: f.remote.Key }
            s3_options =
                Bucket: project_config.AWS_BUCKET
                Delete:
                    Objects: keys
            SDKError.log(SDKError.colors.grey("Deleting #{ keys.length } files from S3..."))
            s3.deleteObjects s3_options, (err) ->
                if err?
                    throw new SDKError('deploy.s3', err)
                _startBatch()
        else
            callback()
    
    _startBatch()

module.exports = (files_to_deploy, project_config, callback) ->
    if files_to_deploy.deleted.length is 0
        callback()
        return

    batches = []

    current_batch = []
    files_to_deploy.deleted.forEach (f, i) ->

        current_batch.push(f)
        if current_batch.length is 1000 or i is files_to_deploy.deleted.length - 1
            batches.push(current_batch)
            current_batch = []
            if i is files_to_deploy.deleted.length - 1
                runBatches(batches, project_config, callback)

