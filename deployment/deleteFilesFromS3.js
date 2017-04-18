/* DECAFFEINATED */

const AWS = require('aws-sdk')

const SDKError = require('../compiler/SDKError')

let runBatches = function(batches, project_config, callback) {

    let s3 = new AWS.S3({
        accessKeyId     : project_config.AWS_ACCESS_KEY_ID,
        secretAccessKey : project_config.AWS_SECRET_ACCESS_KEY
    });

    var _startBatch = function() {
        let batch = batches.shift();
        if (batch) {
            let keys = batch.map(f => ({ Key: f.remote.Key }));
            let s3_options = {
                Bucket: project_config.AWS_BUCKET,
                Delete: {
                    Objects: keys
                }
            };
            SDKError.log(SDKError.colors.grey(`Deleting ${ keys.length } files from S3...`));
            return s3.deleteObjects(s3_options, function(err) {
                if (err != null) {
                    throw new SDKError('deploy.s3', err);
                }
                return _startBatch();
            });
        } else {
            return callback();
        }
    };
    
    return _startBatch();
};

module.exports = function(files_to_deploy, project_config, callback) {
    if (files_to_deploy.deleted.length === 0) {
        callback();
        return;
    }

    let batches = [];

    let current_batch = [];
    return files_to_deploy.deleted.forEach(function(f, i) {

        current_batch.push(f);
        if ((current_batch.length === 1000) || (i === (files_to_deploy.deleted.length - 1))) {
            batches.push(current_batch);
            current_batch = [];
            if (i === (files_to_deploy.deleted.length - 1)) {
                return runBatches(batches, project_config, callback);
            }
        }
    });
};

