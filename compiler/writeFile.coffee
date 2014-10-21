fs      = require 'fs-extra'
path    = require 'path'

module.exports = (build_directory) ->
    return (file_info) ->
        target_file_path = path.join(build_directory, file_info.path)

        _dirname = path.dirname(target_file_path)
        fs.ensureDirSync(_dirname)
        fs.writeFileSync(target_file_path, file_info.content)

        return target_file_path