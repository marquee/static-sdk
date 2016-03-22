# React = require 'react'

SDKError    = require './SDKError'
colors      = SDKError.colors

path        = require 'path'
fs          = require 'fs'
mime        = require 'mime'

module.exports = ({ project_directory, project, config, writeFile, exportMetadata }) ->


    # Require the project's copy of React so that the below validation and
    # rendering will work. Fails silently since React is not required at this
    # point. (For some reason, different copies of React can't validate each
    # other's components?)
    project_react_path = path.join(project_directory, 'node_modules', 'react')
    if fs.existsSync(path.join(project_react_path, 'package.json'))
        React = require(project_react_path)

    _processContent = (file_content, options={}) ->
        switch typeof file_content
            when 'string'
                return [null, file_content]

            when 'object'
                if React?.isValidElement(file_content)
                    output_content = React.renderToStaticMarkup(file_content)
                    output_content = "<!doctype html>#{ output_content }" unless options.fragment
                    return ['text/html', output_content]

                # It looks like a React component but somehow React wasn't
                # installed locally for the project.
                if file_content._store?.props?
                    SDKError.log('project.react', "Did you mean to render a React component? React MUST be installed locally for the project in order to pass `emitFile` a React component.")

                # Try turning the data into JSON
                try
                    output_content = JSON.stringify(file_content)
                catch e
                    throw new SDKError('emitFile.json', e)
                return ['application/json', output_content]
            else
                throw new SDKError('emitFile', "emitFile got unknown type of content: #{ typeof file_content }")

    _processPath = (file_path) ->
        # Turn paths that end in a directory into `path/index.html` for clean URLs
        if file_path.indexOf('.') is -1
            return "#{ file_path }/index.html".replace(/\/{2,}/g,'/')
        return file_path

    files_emitted = []
    files_emitted_indexed = {}

    # The actual function given to the compiler for generating files.
    emitFile = (file_path, file_content, options={}) ->

        # Allow for scoping the entire site under a /path/
        if config.ROOT_PREFIX
            file_path = path.join(config.ROOT_PREFIX, file_path)

        output_path                     = _processPath(file_path)
        [output_type, output_content]   = _processContent(file_content, options)

        if options.content_type
            output_type = options.content_type

        # If _processContent didn't specify a content type, guess based on
        # the output path.
        unless output_type
            output_type = mime.lookup(output_path)

        SDKError.log("Saving #{ colors.green(output_path) } #{ colors.grey('(' + output_content.length + ' bytes, ' + output_type + ')') }")

        writeFile
            path        : output_path
            content     : output_content
            type        : output_type

        files_emitted.push(output_path)
        if files_emitted_indexed[output_path]
            SDKError.warn("File emitted multiple times: #{ output_path }")
        else
            files_emitted_indexed[output_path] = true

        exportMetadata(file_path, options.metadata) if options.metadata

    emitFile.files_emitted = files_emitted
    emitFile.files_emitted_indexed = files_emitted_indexed

    return emitFile

