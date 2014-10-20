# Enable support for requiring `.cjsx` files.
require('coffee-react/register')

fs      = require 'fs'
path    = require 'path'
util    = require 'util'

module.exports = (project_directory) ->
    util.log("Compiling: #{ project_directory }")

    project_package_file = path.join(project_directory, 'package.json')
    unless fs.existsSync(project_package_file)
        throw new Error('Unable to find package.json')

    project_package_content = fs.readFileSync(project_package_file).toString()
    try
        project_package = JSON.parse(project_package_content)
    catch e
        throw new Error('Unable to parse package.json. Is it valid JSON?')

    unless project_package.main
        throw new Error('Project package.json MUST specify a "main"')

    project_main = path.join(project_directory, project_package.main)
    util.log("Project entrypoint: #{ project_main }")

    buildFn = require(project_main)

    buildFn({})

    # make temp directory for asset cache
    # build all assets to asset cache
    # make a temp directory for project
    # copy auto assets
    # build project into temp directory
