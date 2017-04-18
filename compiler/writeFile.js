const fs    = require('fs-extra')
const path  = require('path')

module.exports = function writeFile (build_directory) {
    return function _writeFile (file_info) {
        const target_file_path = path.join(build_directory, file_info.path)
        const _dirname = path.dirname(target_file_path)

        fs.ensureDirSync(_dirname)
        fs.writeFileSync(target_file_path, file_info.content)

        return target_file_path
    }
}
