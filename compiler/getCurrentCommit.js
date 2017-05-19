const fs        = require('fs-extra')
const { exec }  = require('child_process')
const path      = require('path')

module.exports = function getCurrentCommit (directory, callback) {
    // If not a git repository, return null.
    if (!fs.existsSync(path.join(directory, '.git'))) {
        callback(null)
        return
    }
    // http://stackoverflow.com/questions/2657935/checking-for-a-dirty-index-or-untracked-files-with-git
    exec(
        'git diff-index HEAD && git ls-files --exclude-standard --others',
        { cwd: directory },
        (err, stdout, stderr) => {
            if (err) {
                throw err
            } else {
                const _stdout = stdout.trim()
                const is_dirty = _stdout.length !== 0
                const dirty_files = stdout.split('\n').slice(1).join('\n')
                exec(
                    'git rev-parse --short=N HEAD',
                    { cwd: directory },
                    (err, stdout, stderr) => {
                        if (err) {
                            throw err
                        } else {
                            const sha = stdout.split('\n').join('')
                            const commit = `${ sha }${ is_dirty ? '-dirty' : '' }`
                            callback(commit, is_dirty, dirty_files)
                        }
                    }
                )
            }
        }
    )
}