fs      = require 'fs'
mkdirp  = require 'mkdirp'
path    = require 'path'

module.exports = (build_directory) ->
    return (file_info) ->
        target_file_path = path.join(build_directory, file_info.path)

        _dirname = path.dirname(target_file_path)
        unless fs.existsSync(_dirname)
            mkdirp.sync(_dirname)

        fs.writeFileSync(target_file_path, file_info.content)

        return target_file_path