SDKError            = require '../compiler/SDKError'
runCompiler         = require '../compiler'
walkSync            = require '../compiler/walkSync'
getCurrentCommit    = require '../compiler/getCurrentCommit'
putFilesToS3        = require './putFilesToS3'
path                = require 'path'

module.exports = (project_directory, force=false) ->

    getCurrentCommit project_directory, (commit_sha) ->

        # Require deploying from a clean working directory of a version
        # controlled project. Allow for override.
        if not commit_sha
            _repo_message = "No repo detected. It is #{ SDKError.colors.bold('strongly') } recommended to only deploy from a source-controlled project."
            unless force
                throw new SDKError('deploy.repo', "#{ _repo_message }\nUse `#{ SDKError.colors.magenta('marqueestatic deploy --force') }` to override.")
            SDKError.warn('deploy.repo', _repo_message)

        else if commit_sha.split('-').pop() is 'dirty'
            _repo_message = "Uncommitted changes detected. It is #{ SDKError.colors.bold('strongly') } recommended to only deploy from a clean working directory."
            unless force
                throw new SDKError('deploy.repo', "#{ _repo_message }\nUse `#{ SDKError.colors.magenta('marqueestatic deploy --force') }` to override.")
            SDKError.warn('deploy.repo', _repo_message)

        # TODO: warn if branch is not master or behind origin/master


        SDKError.log('Pre-deploy build...\n\n')
        build_directory = runCompiler project_directory, (files, assets, project_package) ->

            console.log('\n')

            ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_BUCKET'].forEach (prop) ->
                unless project_package.marquee[prop]
                    throw new SDKError('configuration.deploy', "Project missing `package.marquee.#{ prop }`.")

            files_to_deploy = walkSync(build_directory, ignore=['.'])
            file_count = SDKError.colors.grey("(#{ files_to_deploy.length } files)")
            _sha = if commit_sha then SDKError.colors.grey("@#{ commit_sha }") else ''
            project_name_and_commit = "#{ SDKError.formatProjectPath(project_directory) }#{ _sha }"
            SDKError.log("Deploying #{ project_name_and_commit } #{ file_count } to #{ SDKError.colors.cyan(project_package.marquee.HOST) }")

            putFilesToS3 build_directory, files_to_deploy, project_package.marquee, ->
                SDKError.log("\nDeployed #{ project_name_and_commit } to #{ SDKError.colors.cyan.underline('http://' + project_package.marquee.HOST) }")