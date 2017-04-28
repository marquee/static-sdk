/* DECAFFEINATED */
const fs = require('fs')
const AWS = require('aws-sdk')

const SDKError = require('../compiler/SDKError')

let getFilesOnS3 = function(project_config, callback) {

    let s3 = new AWS.S3({
        accessKeyId     : project_config.AWS_ACCESS_KEY_ID,
        secretAccessKey : project_config.AWS_SECRET_ACCESS_KEY
    });

    let results = [];

    var _getObjects = function(marker) {

        let s3_options =
            {Bucket          : project_config.AWS_BUCKET};
        if (marker) {
            s3_options.Marker = marker;
        }

        return s3.listObjects(s3_options, function(err, data) {
            if (err != null) { throw new SDKError(err); }
            results.push(...Array.from(data.Contents || []));
            if (data.IsTruncated) {
                return _getObjects(data.Contents[data.Contents.length - 1].Key);
            } else {
                return callback(results);
            }
        });
    };
    return _getObjects();
};

const crypto = require('crypto')
let getEtagFor = function(file) {
    let etag = crypto.createHash('md5');
    etag.update(
            fs.readFileSync(file.local.local_path)
        );
    return etag.digest('hex');
};


module.exports = function(options, build_directory, local_files, project_config, callback) {

    let ignore_prefix_exp = (
        project_config.IGNORE_PREFIX ?
            new RegExp(`^${ project_config.IGNORE_PREFIX }/`)
        :
            null
    );
    let root_prefix_exp = (
        project_config.ROOT_PREFIX ?
            new RegExp(`^${ project_config.ROOT_PREFIX }/`)
        :
            null
    );

    let _isIgnorable = function(key) {
        if (ignore_prefix_exp) {
            return (key.match(ignore_prefix_exp) != null);
        }
        if (root_prefix_exp) {
            return (key.match(root_prefix_exp) == null);
        }
        return false;
    };

    let local_map = new Map();
    let remote_map = new Set();
    local_files.forEach(function(f) {
        let key = f.replace(build_directory, '').substring(1);
        if (!_isIgnorable(key)) {
            return local_map.set(key, {
                local_path: f,
                key
            });
        }
    });

    if (options.build_cache) {
        callback({
            changed: Array.from(local_map.values()).map(v => ({ local: v, remote: null })),
            deleted: [],
            unchanged: []
        });
        return;
    }

    SDKError.log(SDKError.colors.grey("Finding changed/deleted files..."));


    return getFilesOnS3(project_config, function(remote_files) {
        let unknown = [];
        let changed = [];
        let deleted = [];
        let unchanged = [];
        remote_files.forEach(function(f) {
            if (_isIgnorable(f.Key)) {
                return;
            }

            // Ignore files that don't exist locally when deleting of remote
            // files is disabled.
            if (options.no_delete && !local_map.get(f.Key)) {
                return;
            }

            remote_map.add(f.Key);
            if (local_map.get(f.Key) == null) {
                // Files that don't exist locally and need to be deleted from
                // the remote deployment.
                return deleted.push({
                    local: null,
                    remote: f
                });
            } else {
                // Files that exist locally and remotely and need to be checked
                // for sameness.
                return unknown.push({
                    local: local_map.get(f.Key),
                    remote: f
                });
            }
        });

        for (let k in local_map) {
            let v = local_map[k];
            if (!remote_map.has(k)) {
                // Files that exist locally but not remotely and definitely need
                // to be uploaded.
                changed.push({
                    local: v,
                    remote: null
                });
            }
        }

        unknown.forEach(function(f) {
            if (getEtagFor(f) !== JSON.parse(f.remote.ETag)) {
                return changed.push(f);
            } else {
                return unchanged.push(f);
            }
        });

        SDKError.log(SDKError.colors.grey(`Changed: ${ changed.length }, Deleted: ${ deleted.length }, Unchanged: ${ unchanged.length }`));

        return callback({
            changed,
            deleted,
            unchanged
        });
    });
};

