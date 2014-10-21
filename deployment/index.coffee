SDKError            = require '../compiler/SDKError'
runCompiler         = require '../compiler'
walkSync            = require '../compiler/walkSync'
getCurrentCommit    = require '../compiler/getCurrentCommit'

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


        SDKError.log('Pre-deploy build...\n\n')
        build_directory = runCompiler project_directory, (files, assets, project_package) ->

            console.log('\n')

            ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_BUCKET'].forEach (prop) ->
                unless project_package.marquee[prop]
                    throw new SDKError('configuration.deploy', "Project missing `package.marquee.#{ prop }`.")

            files_to_deploy = walkSync(build_directory)
            file_count = SDKError.colors.grey("(#{ files_to_deploy.length } files)")
            _sha = if commit_sha then SDKError.colors.grey("@#{ commit_sha }") else ''
            SDKError.log("Deploying #{ SDKError.formatProjectPath(project_directory) }#{ _sha } #{ file_count } to #{ SDKError.colors.cyan(project_package.marquee.HOST) }")
