/* DECAFFEINATED */



// Enable support for requiring `.cjsx` files.
require('coffee-react/register')
// Enable support for requiring `.jsx` files.
const react_preset = require('babel-preset-react')
const flow_preset = require('babel-preset-flow')
const babel_preset_env = require('babel-preset-env')
require('babel-register')({
    ignore  : /node_modules/,
    presets : [flow_preset, react_preset, babel_preset_env],
    plugins : [
          require('babel-plugin-transform-object-rest-spread')
        , require('babel-plugin-transform-decorators-legacy').default
        , require('babel-plugin-transform-flow-strip-types')
    ]
});



const fs = require('fs-extra')
const path = require('path')

const compileAssets         = require('./compileAssets')
const ContentAPI            = require('./ContentAPI')
const loadConfiguration     = require('./loadConfiguration')
const SDKError              = require('./SDKError')
let { formatProjectPath }   = SDKError;

const getCurrentCommit      = require('./getCurrentCommit')


module.exports = function(project_directory, options, onCompile) {
    if (onCompile == null) { onCompile = null; }
    if (options.ignore_schedule) {
        SDKError.warn('Ignoring release schedule!');
    }

    // Ensure build directory exists and is empty.
    let build_directory = path.join(project_directory, '.dist');
    if (fs.existsSync(build_directory)) {
        SDKError.log(SDKError.colors.grey('Clearing previous build...'));
        fs.removeSync(build_directory);
    }

    // Provide the commit sha to the build, if available.
    getCurrentCommit(project_directory, function(commit_sha, is_dirty) {
        let e, project_package;
        let _sha = commit_sha ? SDKError.colors.grey(`@${ commit_sha }`) : '';
        SDKError.alwaysLog(`Compiling: ${ formatProjectPath(project_directory) }${ _sha }`);

        // Set up or invalidate React cache if necessary
        let build_cache_directory = path.join(project_directory, '.build-cache');
        let build_cache_file = path.join(build_cache_directory, 'cache-v0.9.2.json');
        let build_cache = null;
        if (options.build_cache) {
            if (null == commit_sha) {
                if (!options.force) {
                    SDKError.throw('build-cache.nogit', 'Project is not a git repository. Cannot use build-cache. Use --force to override.');
                }
                SDKError.warn('build-cache.nogit', 'Project is not a git repository. build-cache may produce outdated results!');
            }
            if (is_dirty) {
                if (!options.force) {
                    SDKError.throw('build-cache.dirty', 'Repo has unstaged changes. Cannot use build-cache. Use --force to override.');
                }
                SDKError.warn('build-cache.dirty', 'Repo has unstaged changes. build-cache may produce outdated results!');
            }
            let cache_commit_lock_file = path.join(build_cache_directory, '.commit.lock');

            let build_cache_is_valid = false;
            if (fs.existsSync(build_cache_directory)) {
                let _cache_lock;
                if (fs.existsSync(cache_commit_lock_file)) {
                    _cache_lock = fs.readFileSync(cache_commit_lock_file).toString();
                    build_cache_is_valid = (_cache_lock === commit_sha);
                }
                if (!build_cache_is_valid) {
                    SDKError.log(SDKError.colors.grey(`Resetting build-cache (build-cache@${ _cache_lock }, project@${ commit_sha })...`));
                    fs.removeSync(build_cache_directory);
                } else {
                    SDKError.log(SDKError.colors.grey(`build-cache@${ _cache_lock }`));
                    try {
                        build_cache = new Map(JSON.parse(fs.readFileSync(build_cache_file).toString()));
                    } catch (error) {
                        e = error;
                        SDKError.warn(SDKError.colors.yellow("Unable to parse build-cache file, resetting..."));
                        build_cache_is_valid = false;
                        fs.removeSync(build_cache_directory);
                    }
                }
            }
            if (!build_cache_is_valid) {
                fs.mkdirSync(build_cache_directory);
                fs.writeFileSync(cache_commit_lock_file, commit_sha);
                fs.writeFileSync(build_cache_file, '[]');
                build_cache = new Map();
            }
        }


        // Load the project's package.json file, if present and valid.
        let project_package_file = path.join(project_directory, 'package.json');
        if (!fs.existsSync(project_package_file)) {
            throw new SDKError('package', 'Unable to find package.json');
        }
        let project_package_content = fs.readFileSync(project_package_file).toString();
        try {
            project_package = JSON.parse(project_package_content);
        } catch (error1) {
            e = error1;
            throw new SDKError('package', 'Unable to parse package.json. Is it valid JSON?');
        }

        // Identify the project entrypoint.
        if (!project_package.main) {
            throw new SDKError('configuration', "Project missing `package.main` (typically \"./main.coffee\")");
        }
        let project_main = path.join(project_directory, project_package.main);
        SDKError.log(`Project entrypoint: ${ formatProjectPath(project_directory, project_main) }`);

        // Load and validate the Marquee-specific compiler configuration.
        let project_config = loadConfiguration(project_package, options.configuration);

        ['CONTENT_API_TOKEN', 'CONTENT_API_HOST', 'HOST'].forEach(function(prop) {
            if (!project_config[prop]) {
                let _config_notice = '';
                if (project_package.marquee.configurations || project_package.proof.configurations) {
                    _config_notice = ' A `--configuration <name>` may be required.';
                }
                throw new SDKError('configuration', `Project missing \`package.proof.${ prop }\`.${ _config_notice }`);
            }
        });
        const emitFile = require('./emitFile')
        // Load the project compiler entrypoint.
        let buildFn
        try {
            buildFn = require(project_main)
        } catch (e) {
            if (emitFile.errors_enabled && (options.live_reload || options.inject_live_reload)) {
                emitFile.setBuildError(e, project_directory)
                onCompile([], [], project_package, project_config)
                return
            } else {
                throw e
            }
        }

        emitFile.clearBuildError()
        if (typeof buildFn !== 'function') {
            throw new SDKError('entrypoint', `Project main MUST export a function. Got ${ SDKError.colors.underline(typeof buildFn) }.`);
        }


        // Set up metadata exporting function.
        let metadata_for_s3 = new Map();

        // This is used by the metadata argument of emitFile to gather metadata
        // for each emitted file, to be added to the object’s S3 metadata.
        let _exportMetadata = function(file_path, file_meta) {
            if (file_meta) {
                try {
                    JSON.stringify(file_meta);
                } catch (e) {
                    throw new SDKError('emitFile.metadata', 'emitFile metadata MUST be JSON-serializable');
                }
                if (file_path[0] === '/') {
                    file_path = file_path.substring(1);
                }
                return metadata_for_s3.set(file_path, file_meta);
            }
        };

        // Save out the metadata to a `.metadata.json` file in the build
        // directory. Used by the deploy process to actually apply the metadata.
        let _writeMetadata = function() {
            let _metadata_json = {};
            let iterable = metadata_for_s3.entries();
            for (let v = 0; v < iterable.length; v++) { let k = iterable[v]; _metadata_json[k] = v; }

            let metadata_content = JSON.stringify(_metadata_json);
            SDKError.log(SDKError.colors.grey(`Writing ${ metadata_content.length } bytes of metadata...`));
            return fs.writeFileSync(
                    path.join(build_directory, '.metadata.json'),
                    metadata_content
                );
        };

        // Set up the Content API wrapper for the project.
        let api = new ContentAPI({
            token               : project_config.CONTENT_API_TOKEN,
            host                : project_config.CONTENT_API_HOST,
            project             : project_package,
            config              : project_config,
            project_directory,
            use_cache           : options.use_cache,
            ignore_schedule     : options.ignore_schedule,
            api_page_size       : options.api_page_size,
            smart_cache         : options.smart_cache,
            stale_after         : options.stale_after
        });

        // Create the file handling functions for the project.
        let _writeFile = require('./writeFile')(build_directory);
        let _emitFile = emitFile({
            project_directory,
            project             : project_package,
            config              : project_config,
            writeFile           : _writeFile,
            exportMetadata      : _exportMetadata,
            defer_emits         : options._defer_emits,
            inject_live_reload  : options.inject_live_reload,
            build_cache
        });
        let _emitRedirect = require('./emitRedirect')(_emitFile);
        let _emitRSS = require('./emitRSS')(_emitFile);
        let _processSiteDescription = require('../declarative/processSiteDescription')({
            project_directory   : project_directory,
            project             : project_package,
            config              : project_config,
            emitFile            : _emitFile,
        });

        // Set a timeout for the compiler.
        let TIMEOUT = 30 * 60; // 30 minutes
        let _done_timeout = setTimeout(function() {
            throw new SDKError('compiler', `Compiler timeout. Compiler MUST call \`done\` within ${ TIMEOUT } seconds.`);
        }
        , TIMEOUT * 1000);

        let _done = function(site_description=null) {
            SDKError.clearPrefix();
            clearTimeout(_done_timeout);

            if (null != site_description) {
                _processSiteDescription(site_description)
            }

            if (!options.skip_build_info) {
                let _info_to_emit = {
                    date            : build_info.date,
                    commit          : build_info.commit,
                    assets          : build_info.asset_hash,
                    publication     : project_config.PUBLICATION_SHORT_NAME,
                    env             : process.env.NODE_ENV,
                    configuration   : options.configuration,
                    priority        : options.priority === Infinity ? null : options.priority
                };

                _emitFile('/_build_info/last.json', _info_to_emit);
                _emitFile(`/_build_info/${ options.priority === Infinity ? 'full' : options.priority }.json`, _info_to_emit);
            }


            _writeMetadata();
            // Check that the project has necessary files.
            if (!_emitFile.files_emitted_indexed.get('404.html') && !_emitFile.files_emitted_indexed.get('/404.html')) {
                SDKError.warn('files', 'Projects SHOULD have a /404.html');
            }
            if (!_emitFile.files_emitted_indexed.get('index.html') && !_emitFile.files_emitted_indexed.get('/index.html')) {
                SDKError.warn('files', 'Projects SHOULD have a /index.html');
            }

            if (build_cache != null) {
                let build_cache_str = JSON.stringify(Array.from(build_cache.entries()));
                SDKError.log(`Saving build-cache file (${ build_cache_str.length } bytes) ...`);
                fs.writeFileSync(build_cache_file, build_cache_str);
            }

            let num_indexed = _emitFile.files_emitted_indexed.size;
            let num_emitted = _emitFile.files_emitted.length;
            if (num_indexed !== num_emitted) {
                SDKError.warn('files', `${ num_emitted - num_indexed } too many emits. Check for multiple emits of the same file.`);
            }
            emitFile.enableErrors()
            return (typeof onCompile === 'function' ? onCompile(_emitFile.files_emitted, compileAssets.files_emitted, project_package, project_config) : undefined);
        };

        return compileAssets({
            build_cache,
            project_directory,
            build_directory,
            allow_asset_errors: options.allow_asset_errors,
            hash_files          : process.env.NODE_ENV === 'production',
            project_config,
            command_options: options,
            callback(asset_hash) {
                // Make the config globally available. Yes, globals are Bad(tm), but this
                // makes for a substantially simpler compiler.
                let _prefix, asset_dest_directory;
                global.config = project_config;
                if (project_config.ROOT_PREFIX) {
                    asset_dest_directory = path.join(build_directory, project_config.ROOT_PREFIX, 'assets');
                    _prefix = `/${ project_config.ROOT_PREFIX }`;
                } else {
                    asset_dest_directory = path.join(build_directory, 'assets');
                    _prefix = '';
                }
                if (asset_hash) {
                    asset_dest_directory = path.join(asset_dest_directory, asset_hash);
                }
                let build_info = {
                    project_directory,
                    commit                  : commit_sha,
                    date                    : new Date(),
                    asset_hash,
                    build_directory,
                    asset_dest_directory,
                    asset_cache_directory   : path.join(project_directory, '.asset-cache')
                };
                global.build_info = build_info;

                if (project_config.FULLY_QUALIFY_ASSET_URL) {
                    _prefix = `//${ project_config.HOST }${ _prefix }`;
                }

                if (asset_hash) {
                    global.ASSET_URL = `${ _prefix }/assets/${ asset_hash }/`;
                } else {
                    global.ASSET_URL = `${ _prefix }/assets/`;
                }


                let _emitAssets = (...args) =>
                    compileAssets.includeAssets({
                        project_directory,
                        build_directory,
                        asset_hash,
                        assets              : args
                    })
                ;

                // Finally, invoke the compiler.
                SDKError.alwaysLog(`Invoking compiler from ${ SDKError.colors.green(project_package.main) }`);
                SDKError.setPrefix(SDKError.colors.grey('* compiler: '));
                try {
                    let result_promise = buildFn({
                        api,
                        emitFile        : _emitFile,
                        emitRedirect    : _emitRedirect,
                        emitRSS         : _emitRSS,
                        emitAssets      : _emitAssets,
                        config          : project_config,
                        project         : project_package,
                        payload         : options.payload,
                        done            : _done,
                        info            : build_info,
                        includeAssets(...args) {
                            SDKError.warn('`includeAssets` is deprecated. Used `emitAssets`.');
                            return _emitAssets(...Array.from(args || []));
                        },
                        PRIORITY        : options.priority
                    });
                    __guardMethod__(result_promise, 'then', o => o.then(_done));
                    // If the buildFn correctly returns a promise, use that
                    // instead of the surrounding try/catch to guard
                    // against errors.
                    return __guardMethod__(result_promise, 'catch', o1 => o1.catch(function(e) {
                        clearTimeout(_done_timeout);
                        SDKError.throw('compiler', e);
                    }));
                } catch (error2) {
                    e = error2;
                    clearTimeout(_done_timeout);
                    SDKError.throw('compiler', e);
                }
            }
        });
    });

    return build_directory;
};

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}
