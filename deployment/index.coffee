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

module.exports = (project_directory, options={}) ->

    SDKError.log(SDKError.colors.grey("Attempting to deploy: #{ project_directory }"))

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

        SDKError.log('Pre-deploy build...\n\n')
        build_directory = runCompilation project_directory, options, (files, assets, project_package) ->

            project_config = loadConfiguration(project_package, options.configuration)

            ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_BUCKET'].forEach (prop) ->
                unless project_config[prop]
                    throw new SDKError('configuration.deploy', "Project missing `package.marquee.#{ prop }`.")


            # Allow _ prefixed files through the deploy process.
            local_files = walkSync(build_directory, ['.'])
            minifyAndCompressInPlace local_files, ->
                getChangedFiles build_directory, local_files, project_config, (files_to_deploy) ->

                    file_count = SDKError.colors.grey("(#{ files_to_deploy.changed.length + files_to_deploy.deleted.length } files changed, #{ local_files.length } total)")
                    _sha = if commit_sha then SDKError.colors.grey("@#{ commit_sha }") else ''
                    project_name_and_commit = "#{ SDKError.formatProjectPath(project_directory) }#{ _sha }"
                    SDKError.alwaysLog("Deploying #{ project_name_and_commit } #{ file_count } to #{ SDKError.colors.cyan(project_config.HOST) }")

                    putFilesToS3 build_directory, files_to_deploy, project_config, ->
                        deleteFilesFromS3 files_to_deploy, project_config, ->
                            SDKError.alwaysLog("Deployed #{ project_name_and_commit } to #{ SDKError.colors.cyan.underline('http://' + project_config.HOST) }")