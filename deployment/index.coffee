SDKError                    = require '../compiler/SDKError'
runCompilation              = require '../compiler'
walkSync                    = require '../compiler/walkSync'
getCurrentCommit            = require '../compiler/getCurrentCommit'
loadConfiguration           = require '../compiler/loadConfiguration'
putFilesToS3                = require './putFilesToS3'
getChangedFiles             = require './getChangedFiles'
deleteFilesFromS3           = require './deleteFilesFromS3'
minifyAndCompressInPlace    = require './minifyAndCompressInPlace'
path                        = require 'path'
fs                          = require 'fs'

module.exports = (project_directory, options={}) ->
    deploy_timers = {}

    _start_date = new Date()

    SDKError.log(SDKError.colors.grey("#{ if options.fake_deploy then '(fake) ' else '' }Attempting to deploy: #{ project_directory }"))

    getCurrentCommit project_directory, (commit_sha) ->

        # Require deploying from a clean working directory of a version
        # controlled project. Allow for override.
        if not commit_sha
            _repo_message = "No repo detected. It is #{ SDKError.colors.bold('strongly') } recommended to only deploy from a source-controlled project."
            unless options.force
                throw new SDKError('deploy.repo', "#{ _repo_message }\nUse `#{ SDKError.colors.magenta('marqueestatic deploy --force') }` to override.")
            SDKError.warn('deploy.repo', _repo_message)

        else if commit_sha.split('-').pop() is 'dirty'
            _repo_message = "Uncommitted changes detected. It is #{ SDKError.colors.bold('strongly') } recommended to only deploy from a clean working directory."
            unless options.force
                throw new SDKError('deploy.repo', "#{ _repo_message }\nUse `#{ SDKError.colors.magenta('marqueestatic deploy --force') }` to override.")
            SDKError.warn('deploy.repo', _repo_message)

        # TODO: warn if branch is not master or behind origin/master

        _build_start = Date.now()

        SDKError.log('Pre-deploy build...\n\n')
        build_directory = runCompilation project_directory, options, (files, assets, project_package) ->

            deploy_timers.ms_build = Date.now() - _build_start

            project_config = loadConfiguration(project_package, options.configuration)

            ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_BUCKET'].forEach (prop) ->
                unless project_config[prop]
                    throw new SDKError('configuration.deploy', "Project missing `package.marquee.#{ prop }`.")

            _minify_start = Date.now()

            # Allow _ prefixed files through the deploy process.
            local_files = walkSync(build_directory, ['.'])

            minifyAndCompressInPlace local_files, ->
                deploy_timers.ms_minify = Date.now() - _minify_start

                _changed_start = Date.now()
                getChangedFiles build_directory, local_files, project_config, (files_to_deploy) ->
                    deploy_timers.ms_changed = Date.now() - _changed_start

                    file_count = SDKError.colors.grey("(#{ files_to_deploy.changed.length + files_to_deploy.deleted.length } files changed, #{ local_files.length } total)")
                    _sha = if commit_sha then SDKError.colors.grey("@#{ commit_sha }") else ''
                    project_name_and_commit = "#{ SDKError.formatProjectPath(project_directory) }#{ _sha }"
                    SDKError.alwaysLog("Deploying #{ project_name_and_commit } #{ file_count } to #{ SDKError.colors.cyan(project_config.HOST) }")

                    _s3_start = Date.now()

                    _uploadDone = ->
                        deploy_timers.ms_upload = Date.now() - _s3_start
                        deploy_timers.ms_total = Date.now() - _start_date.getTime()
                        deploy_stats =
                            publication     : project_config.PUBLICATION_SHORT_NAME
                            version         : commit_sha
                            start_date      : _start_date
                            configuration   : options.configuration
                            files:
                                num_changed     : files_to_deploy.changed.length
                                num_deleted     : files_to_deploy.deleted.length
                                num_unchanged   : files_to_deploy.unchanged.length
                                num_total       : local_files.length
                                percent_changed : files_to_deploy.changed.length / local_files.length
                                percent_deleted : files_to_deploy.deleted.length / local_files.length
                            timing: deploy_timers
                        if options.deploy_stats
                            _stats_file = options.deploy_stats
                            unless _stats_file[0] is '/'
                                _stats_file = path.join(process.cwd(), _stats_file)
                            SDKError.log("Saving stats to #{ _stats_file }")
                            fs.writeFileSync(
                                    _stats_file
                                    JSON.stringify(deploy_stats)
                                )
                        SDKError.alwaysLog("Deployed #{ project_name_and_commit } to #{ SDKError.colors.cyan.underline('http://' + project_config.HOST) }")

                    if options.fake_deploy
                        SDKError.alwaysLog('Simulated deploy. Skipping upload...')
                        _uploadDone()
                        return

                    putFilesToS3 options, build_directory, files_to_deploy, project_config, ->
                        if options.no_delete
                            _uploadDone()
                        else
                            deleteFilesFromS3 files_to_deploy, project_config, ->
                                _uploadDone()

