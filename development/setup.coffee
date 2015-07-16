prompt  = require 'prompt'
fs      = require 'fs'
crypto  = require 'crypto'
path    = require 'path'


updatePackageJSON = (package_json_path, config) ->
    pkg = JSON.parse(fs.readFileSync(package_json_path).toString())
    if pkg.marquee and typeof pkg.marquee isnt 'string'
        throw new Error('Already set up!')
    delete pkg.scripts.setup
    pkg.marquee                     = config
    pkg.marquee.auto_assets         = true
    pkg.marquee.WEBHOOK_TOKEN       = crypto.randomBytes(20).toString('hex')
    pkg.marquee.CONTENT_API_HOST    = 'api.marquee.by'
    pkg.scripts.build               = 'npm install && ./node_modules/.bin/marqueestatic build --verbose'
    pkg.scripts.develop             = 'npm install && ./node_modules/.bin/marqueestatic develop --verbose --use-cache'
    pkg.scripts.deploy              = 'npm install && ./node_modules/.bin/marqueestatic deploy --verbose'

    fs.writeFileSync(package_json_path, JSON.stringify(pkg, null, 2))




module.exports = (project_directory, options) ->

    package_json_path = path.join(project_directory, 'package.json')

    prompt.message = ''
    prompt.start()

    prompt.get [
        {
            name        : 'PUBLICATION_SHORT_NAME'
            description : 'Publication short_name'
            required    : true
            conform     : (value) -> /^[a-z0-9_\-]+$/.test(value)
        }
        {
            name        : 'CONTENT_API_TOKEN'
            description : 'Content API token (read-only)'
            required    : true
            message     : 'Must be a valid read-only token'
            conform     : (value) -> /r0_[0-9a-f]{40}/.test(value)
        }
        {
            name        : 'HOST'
            description : 'Host'
            required    : false
            default     : 'localhost:5000'
        }
    ], (err, result) ->
        if result.HOST isnt 'localhost:5000'
            prompt.get [
                {
                    name        : 'AWS_ACCESS_KEY_ID'
                    description : 'AWS Access Key ID'
                    required    : true
                }
                {
                    name        : 'AWS_SECRET_ACCESS_KEY'
                    description : 'AWS Secret Access Key'
                    required    : true
                }
                {
                    name        : 'AWS_BUCKET'
                    description : 'AWS Bucket'
                    required    : false
                    default     : result.HOST
                }
            ], (err, extra_result) ->
                for k,v of extra_result
                    result[k] = v
                updatePackageJSON(package_json_path, result)
        else
            ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_BUCKET'].forEach (prop) ->
                result[prop] = ''
            updatePackageJSON(package_json_path, result)

