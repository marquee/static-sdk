/* DECAFFEINATED */

const SDKError = require('../compiler/SDKError')
const runCompilation = require('../compiler')
const walkSync = require('../compiler/walkSync')
const getCurrentCommit = require('../compiler/getCurrentCommit')
const loadConfiguration = require('../compiler/loadConfiguration')
const putFilesToS3 = require('./putFilesToS3')
const getChangedFiles = require('./getChangedFiles')
const deleteFilesFromS3 = require('./deleteFilesFromS3')
const minifyAndCompressInPlace = require('./minifyAndCompressInPlace')
const path = require('path')
const fs = require('fs')

module.exports = function(project_directory, options) {
    if (options == null) { options = {}; }
    let deploy_timers = {};

    let _start_date = new Date();

    SDKError.log(SDKError.colors.grey(`${ options.fake_deploy ? '(fake) ' : '' }Attempting to deploy: ${ project_directory }`));

    return getCurrentCommit(project_directory, function(commit_sha) {

        // Require deploying from a clean working directory of a version
        // controlled project. Allow for override.
        let _repo_message, build_directory;
        if (!commit_sha) {
            _repo_message = `No repo detected. It is ${ SDKError.colors.bold('strongly') } recommended to only deploy from a source-controlled project.`;
            if (!options.force) {
                throw new SDKError('deploy.repo', `${ _repo_message }\nUse \`${ SDKError.colors.magenta('proof deploy --force') }\` to override.`);
            }
            SDKError.warn('deploy.repo', _repo_message);

        } else if (commit_sha.split('-').pop() === 'dirty') {
            _repo_message = `Uncommitted changes detected. It is ${ SDKError.colors.bold('strongly') } recommended to only deploy from a clean working directory.`;
            if (!options.force) {
                throw new SDKError('deploy.repo', `${ _repo_message }\nUse \`${ SDKError.colors.magenta('proof deploy --force') }\` to override.`);
            }
            SDKError.warn('deploy.repo', _repo_message);
        }

        // TODO: warn if branch is not master or behind origin/master

        let _build_start = Date.now();

        SDKError.log('Pre-deploy build...\n\n');
        return build_directory = runCompilation(project_directory, options, function(files, assets, project_package) {

            deploy_timers.ms_build = Date.now() - _build_start;

            let project_config = loadConfiguration(project_package, options.configuration);

            ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_BUCKET'].forEach(function(prop) {
                if (!project_config[prop]) {
                    throw new SDKError('configuration.deploy', `Project missing \`package.proof.${ prop }\`.`);
                }
            });

            let _minify_start = Date.now();

            // Allow _ prefixed files through the deploy process.
            let local_files = walkSync(build_directory, ['.']);

            return minifyAndCompressInPlace(local_files, function() {
                deploy_timers.ms_minify = Date.now() - _minify_start;

                let _changed_start = Date.now();
                return getChangedFiles(options, build_directory, local_files, project_config, function(files_to_deploy) {
                    deploy_timers.ms_changed = Date.now() - _changed_start;

                    let file_count = SDKError.colors.grey(`(${ files_to_deploy.changed.length + files_to_deploy.deleted.length } files changed, ${ local_files.length } total)`);
                    let _sha = commit_sha ? SDKError.colors.grey(`@${ commit_sha }`) : '';
                    let project_name_and_commit = `${ SDKError.formatProjectPath(project_directory) }${ _sha }`;
                    SDKError.alwaysLog(`Deploying ${ project_name_and_commit } ${ file_count } to ${ SDKError.colors.cyan(project_config.HOST) }`);

                    let _s3_start = Date.now();

                    let _uploadDone = function() {
                        deploy_timers.ms_upload = Date.now() - _s3_start;
                        deploy_timers.ms_total = Date.now() - _start_date.getTime();
                        let deploy_stats = {
                            publication     : project_config.PUBLICATION_SHORT_NAME,
                            version         : commit_sha,
                            start_date      : _start_date,
                            configuration   : options.configuration,
                            files: {
                                num_changed     : files_to_deploy.changed.length,
                                num_deleted     : files_to_deploy.deleted.length,
                                num_unchanged   : files_to_deploy.unchanged.length,
                                num_total       : local_files.length,
                                percent_changed : files_to_deploy.changed.length / local_files.length,
                                percent_deleted : files_to_deploy.deleted.length / local_files.length
                            },
                            timing: deploy_timers
                        };
                        if (options.deploy_stats) {
                            let _stats_file = options.deploy_stats;
                            if (_stats_file[0] !== '/') {
                                _stats_file = path.join(process.cwd(), _stats_file);
                            }
                            SDKError.log(`Saving stats to ${ _stats_file }`);
                            fs.writeFileSync(
                                    _stats_file,
                                    JSON.stringify(deploy_stats)
                                );
                        }
                        return SDKError.alwaysLog(`Deployed ${ project_name_and_commit } to ${ SDKError.colors.cyan.underline(`http://${project_config.HOST}`) }`);
                    };

                    if (options.fake_deploy) {
                        SDKError.alwaysLog('Simulated deploy. Skipping upload...');
                        _uploadDone();
                        return;
                    }

                    return putFilesToS3(options, build_directory, files_to_deploy, project_config, function() {
                        if (options.no_delete) {
                            return _uploadDone();
                        } else {
                            return deleteFilesFromS3(files_to_deploy, project_config, () => _uploadDone());
                        }
                    });
                });
            });
        });
    });
};

