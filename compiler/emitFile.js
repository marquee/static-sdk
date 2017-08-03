/* DECAFFEINATED */
const React = require('react')
const ReactDOMServer = require('react-dom/server')

const SDKError = require('./SDKError');
let { colors }      = SDKError;

const path = require('path')
const fs = require('fs')
const mime = require('mime')
const crypto = require('crypto')

// Create a singular cache of the emits so that the development server always
// uses the same emit cache as each build. Otherwise it won't see changes.
let emit_cache = new Map();

const circularJSONStringify = require('./circularJSONStringify')

const ERROR_STYLES = 'display: block; font-family: monospace; border-bottom: 3px solid red; padding: 24px; background-color: white; white-space: pre;'

function renderJSErrorMessage (err, project_directory) {
    const formatted_error = `Server-side compilation error:
file: ${ err.filename ? err.filename : '?' }
line: ${ err.loc ? err.loc.line : '?' }, column: ${ err.loc ? err.loc.column : '?' }

${ err.toString().replace(project_directory, '') }

${ err.stack.toString() }
`
    return `<!doctype html><html>
<head>
    <style>body { ${ ERROR_STYLES } }</style>
</head>
<body>
<script>
    document.write(
        decodeURIComponent(
            "${ encodeURIComponent(formatted_error) }"
        )
    )
</script>
${ LIVE_RELOAD_TAG }
</body>
<html>
`
}

const LIVE_RELOAD_TAG = `<script>document.write('<script src="http://'
+ (window.location.host || 'localhost').split(':')[0]
+ ':35729/livereload.js?snipver=1"></'
+ 'script>')</script>`
function injectLiveReloadTag (markup) {
    SDKError.log(SDKError.colors.grey(`Injecting live reload script...`));
    return markup.replace(/\<\/body\>\<\/html\>$/, LIVE_RELOAD_TAG + '</body></html>')
}


let getContentChecksum = function(content) {
    let hashed_content = crypto.createHash('md5').update(
        content
    ).digest('hex');
    return `${ global.build_info.commit }/${ global.build_info.asset_hash }/raw_content=${ hashed_content }`;
};

let getReactChecksum = function(element) {
    let hashed_props = crypto.createHash('md5').update(
        circularJSONStringify(element.props)
    ).digest('hex');
    return `${ global.build_info.commit }/${ global.build_info.asset_hash }/${ element.type.name || element.type.displayName || 'React.Component' }-props=${ hashed_props }`;
};

let getCacheKey = filepath => crypto.createHash('md5').update(filepath).digest('hex');


module.exports = function({ project_directory, project, config, writeFile, exportMetadata, defer_emits, build_cache, inject_live_reload }) {

    // Require the project's copy of React so that the below validation and
    // rendering will work. Fails silently since React is not required at this
    // point. (For some reason, different copies of React can't validate each
    // other's components?)
    let files_emitted_indexed;
    let project_react_path = path.join(project_directory, 'node_modules', 'react');

    let _processContent = function(file_content, options) {
        let output_content;
        if (options == null) { options = {}; }
        switch (typeof file_content) {
            case 'string':
                return [null, file_content];

            case 'object':
                if (React.isValidElement(file_content)) {
                    output_content = ReactDOMServer.renderToStaticMarkup(file_content);
                    if (inject_live_reload) {
                        output_content = injectLiveReloadTag(output_content)
                    }
                    if (!options.fragment) {
                        // Allow overriding of doctype appending.
                        if (false !== options.doctype) {
                            if (null != options.doctype) {
                                output_content = `${ options.doctype }${ output_content }`;
                            } else {
                                output_content = `<!doctype html>${ output_content }`;
                            }
                        }
                    }
                    return ['text/html', output_content];
                }

                // It looks like a React component but somehow React wasn't
                // installed locally for the project.
                if ((file_content._store != null ? file_content._store.props : undefined) != null) {
                    SDKError.log('project.react', "Did you mean to render a React component? React MUST be installed locally for the project in order to pass `emitFile` a React component.");
                }

                // Try turning the data into JSON
                try {
                    output_content = JSON.stringify(file_content);
                } catch (e) {
                    throw new SDKError('emitFile.json', e);
                }
                return ['application/json', output_content];
            default:
                throw new SDKError('emitFile', `emitFile got unknown type of content: ${ typeof file_content }`);
        }
    };

    let _processPath = function(file_path) {
        // Turn paths that end in a directory into `path/index.html` for clean URLs
        if (file_path.indexOf('.') === -1) {
            return `${ file_path }/index.html`.replace(/\/{2,}/g,'/');
        }
        return file_path;
    };

    let files_emitted = [];

    if (defer_emits) {
        // Reuse the existing cache object so the development server can see
        // the changes, but be sure to flush it for consistency.
        files_emitted_indexed = emit_cache;
        files_emitted_indexed.clear();
    } else {
        files_emitted_indexed = new Map();
    }

    // The actual function given to the compiler for generating files.
    let emitFile = function(file_path, file_content, options) {

        // Using variable-defined paths can easily cause undefined to be used.
        if (options == null) { options = {}; }
        if (file_path == null) {
            throw new SDKError('emitFile.path', 'emitFile got an undefined path');
        }

        // Allow for scoping the entire site under a /path/
        if (config.ROOT_PREFIX) {
            file_path = path.join(config.ROOT_PREFIX, file_path);
        }

        let output_path     = _processPath(file_path);
        let output_type     = null;
        let output_content  = null;

        let _doProcess = function() {
            let _new_checksum, _output_content, _output_type;
            let _output_cache = null;
            let _checksum = null;

            if (build_cache != null) {
                if (React.isValidElement(file_content)) {
                    _new_checksum = getReactChecksum(file_content);
                } else if (typeof file_content === 'string') {
                    _new_checksum = getContentChecksum(file_content);
                }
            }

            if (build_cache && output_path && _new_checksum && (_new_checksum === build_cache.get(output_path))) {
                SDKError.log(colors.grey(`Skipping unchanged build-cache version of ${ output_path }@${ _new_checksum }`));
                _output_type = null;
                _output_content = null;
            } else {
                [_output_type, _output_content] = Array.from(_processContent(file_content, options));
                if (build_cache && _new_checksum) {
                    SDKError.log(colors.grey(`Adding to build-cache: ${ output_path }@${ _new_checksum }`));
                    build_cache.set(output_path, _new_checksum);
                }
            }

            let output_content_to_render = file_content;
            output_type = _output_type;
            output_content = _output_content;

            if (options.content_type) {
                output_type = options.content_type;
            }

            // If _processContent didn't specify a content type, guess based on
            // the output path.
            if (!output_type) {
                output_type = mime.lookup(output_path);
            }

            if (!defer_emits && !!output_content) {
                SDKError.log(`Saving ${ colors.green(output_path) } ${ colors.grey(`(${output_content.length} bytes, ${output_type})`) }`);
                writeFile({
                    path        : output_path,
                    content     : output_content,
                    type        : output_type
                });
            }
            return [output_type, output_content];
        };

        if (!defer_emits) {
            _doProcess();
        }

        if (defer_emits || output_content) {
            files_emitted.push(output_path);
            if (files_emitted_indexed.get(output_path)) {
                SDKError.warn(`File emitted multiple times: ${ output_path }`);
            } else {
                files_emitted_indexed.set(output_path, {
                    path: output_path,
                    // Avoid hanging on to the _doProcess function to prevent
                    // a memory leak.
                    render: defer_emits ? _doProcess : null,
                    type: output_type,
                });
            }
            output_content = null;

            if (options.metadata) { return exportMetadata(file_path, options.metadata); }
        }
    };

    emitFile.files_emitted = files_emitted;
    files_emitted._indexed = files_emitted_indexed;
    emitFile.files_emitted_indexed = files_emitted_indexed;

    return emitFile;
};

function setBuildError (error, project_directory) {
    console.log('\n')
    console.error(error)
    console.log('\n')
    require('../development/current_error').error = renderJSErrorMessage(error, project_directory)
}

module.exports.setBuildError = setBuildError

module.exports.clearBuildError = () => {
    require('../development/current_error').error = null
}

module.exports.errors_enabled = false
module.exports.enableErrors = () => {
    module.exports.errors_enabled = true
}
