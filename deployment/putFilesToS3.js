/* DECAFFEINATED */

const mime = require('mime')


const AWS = require('aws-sdk')

const SDKError = require('../compiler/SDKError')

const fs = require('fs')
const path = require('path')


const COMPRESSABLE = ['js', 'css', 'svg', 'html', 'txt', 'json', 'xml'];

let DEFAULT_CACHE_CONTROLS = {
    'html'  : 'max-age=1800', // 30 min
    'json'  : 'max-age=3600', // 60 min
    // These are served under a content-based hash so they should be cached indefinitely.
    'js'    : 'max-age=31536000', // one year (typical valid max)
    'css'   : 'max-age=31536000', // one year
    'jpg'   : 'max-age=31536000', // one year
    'png'   : 'max-age=31536000', // one year
    'ico'   : 'max-age=31536000' // one year
};


module.exports = function(options, build_directory, files_to_deploy, project_config, callback) {
    if (files_to_deploy.changed.length === 0) {
        callback();
        return;
    }

    let s3 = new AWS.S3({
        accessKeyId     : project_config.AWS_ACCESS_KEY_ID,
        secretAccessKey : project_config.AWS_SECRET_ACCESS_KEY
    });

    let total_uploaded = 0;

    let to_upload = files_to_deploy.changed.length;

    let metadata = JSON.parse(
            fs.readFileSync(
                    path.join(build_directory, '.metadata.json')
                ).toString()
        );

    // Sort files by reverse "depth". This helps ensure that entries get
    // uploaded before links to them are (ie the homepage).
    files_to_deploy.changed.sort((a,b) => b.local.local_path.split('/').length - a.local.local_path.split('/').length);

    let num_active_uploads = 0;

    let uploadFile = function(f, cb) {
        let rel_path = f.local.local_path.replace(build_directory + '/','');

        // Read the file synchronously. Async results in too many open files.
        let file_content = fs.readFileSync(f.local.local_path);
        let _ext = rel_path.split('.').pop();

        let s3_options = {
            Bucket          : project_config.AWS_BUCKET,
            Key             : rel_path,
            ACL             : 'public-read',
            ContentType     : mime.lookup(rel_path),
            StorageClass    : 'REDUCED_REDUNDANCY'
        };

        // Apply per-extension project-configured CacheControl values.
        if (project_config.cache_control != null ? project_config.cache_control[_ext] : undefined) {
            s3_options.CacheControl = project_config.cache_control[_ext];
        // Apply per-extension default CacheControl values.
        } else if (DEFAULT_CACHE_CONTROLS[_ext]) {
            s3_options.CacheControl = DEFAULT_CACHE_CONTROLS[_ext];
        }

        // Apply per-file metadata.
        if (metadata[rel_path]) {
            s3_options.Metadata = metadata[rel_path];
            for (let k in metadata[rel_path]) {
                // ContentType and CacheControl can be overridden.
                let v = metadata[rel_path][k];
                if (k.toLowerCase() === 'content-type') {
                    s3_options.ContentType = v;
                } else if (k.toLowerCase() === 'cache-control') {
                    s3_options.CacheControl = v;
                // Other metadata gets scoped under Metadata.
                } else {
                    if (s3_options.Metadata == null) { s3_options.Metadata = {}; }
                    s3_options.Metadata[k] = v;
                }
            }
        }

        let _upload = function(body) {
            total_uploaded += body.length;
            s3_options.Body = body;
            let _file_size = SDKError.colors.grey(`(${ body.length } bytes, ${ s3_options.ContentType })`);
            SDKError.log(`Uploading ${ SDKError.colors.cyan(rel_path) }... ${ _file_size }`);
            // Put the compressed page HTML at the target S3 key.
            return s3.putObject(s3_options, function(err, data) {
                if (err != null) {
                    let _err = new SDKError('deploy.s3', err);
                    if (options.skip_upload_errors) {
                        console.error(_err);
                    } else {
                        throw _err;
                    }
                } else {
                    SDKError.log(`Saved ${ SDKError.colors.green(rel_path) }.`);
                }

                return cb();
            });
        };

        if (Array.from(COMPRESSABLE).includes(_ext)) {
            s3_options.ContentEncoding = 'gzip';
        }
        return _upload(file_content);
    };

    let BATCH_SIZE = options.batch_size || 5;

    let i = -1;
    var cycleUpload = function() {
        i += 1;
        let f = files_to_deploy.changed[i];
        if (f) {
            num_active_uploads += 1;
            return process.nextTick(() =>
                uploadFile(f, function() {
                    num_active_uploads -= 1;
                    to_upload -= 1;
                    if (to_upload === 0) {
                        let _file_count = SDKError.colors.green(`${ files_to_deploy.changed.length } files, ${ total_uploaded } bytes`);
                        SDKError.log(`Uploaded ${ _file_count } to ${ SDKError.colors.cyan(project_config.AWS_BUCKET) }`);
                        return callback();
                    } else {
                        return (() => {
                            let result = [];
                            while ((num_active_uploads < BATCH_SIZE) && (i < files_to_deploy.changed.length)) {
                                result.push(cycleUpload());
                            }
                            return result;
                        })();
                    }
                })
            );
        }
    };

    return (() => {
        let result = [];
        while ((num_active_uploads < BATCH_SIZE) && (i < files_to_deploy.changed.length)) {
            result.push(cycleUpload());
        }
        return result;
    })();
};

