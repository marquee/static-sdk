fs          = require 'fs-extra'
{ exec }    = require 'child_process'
path        = require 'path'

module.exports = getCurrentCommit = (directory, cb) ->

    # If not a git repository, return null.
    unless fs.existsSync(path.join(directory, '.git'))
        cb(null)
        return

    # http://stackoverflow.com/questions/2657935/checking-for-a-dirty-index-or-untracked-files-with-git
    exec 'git diff-index HEAD && git ls-files --exclude-standard --others', cwd: directory, (err, stdout, stderr) ->
        is_dirty = stdout.trim().length isnt 0
        exec 'git rev-parse --short=N HEAD', cwd: directory, (err, stdout, stderr) ->
            sha = stdout.split('\n').join('')
            cb("#{ sha }#{ if is_dirty then '-dirty' else '' }", is_dirty)
