const prompt  = require('prompt')
const fs      = require('fs')
const crypto  = require('crypto')
const path    = require('path')


function updatePackageJSON (package_json_path, config) {
    const pkg = JSON.parse(fs.readFileSync(package_json_path).toString())
    if (pkg.proof && typeof pkg.proof !== 'string') {
        throw new Error('Already set up!')
    }
    delete pkg.scripts.setup
    pkg.proof                       = config
    pkg.proof.CONTENT_API_HOST      = 'api.proof.pub'
    pkg.proof.cache_control = {
        'html': 'max-age=60'
    }
    pkg.scripts.build               = 'npm install && proof build --verbose'
    pkg.scripts.develop             = 'npm install && proof develop --verbose --use-cache'
    pkg.scripts.deploy              = 'git push origin master'
    fs.writeFileSync(package_json_path, JSON.stringify(pkg, null, 2))
}



module.exports = function (project_directory, options) {

    const package_json_path = path.join(project_directory, 'package.json')

    prompt.message = ''
    prompt.start()

    prompt.get([
        {
            name        : 'PUBLICATION_SHORT_NAME',
            description : 'Publication short_name',
            required    : true,
            conform     : value => /^[a-z0-9_\-]+$/.test(value),
        },
        {
            name        : 'CONTENT_API_TOKEN',
            description : 'Content API token (read-only)',
            required    : true,
            message     : 'Must be a valid read-only token',
            conform     : value => /r0_[0-9a-f]{40}/.test(value),
        },
        {
            name        : 'HOST',
            description : 'Host',
            required    : false,
            default     : 'localhost:5000',
        }
    ], (err, result) => {
        if (result.HOST !== 'localhost:5000') {
            prompt.get([
                {
                    name        : 'AWS_ACCESS_KEY_ID',
                    description : 'AWS Access Key ID',
                    required    : true,
                },
                {
                    name        : 'AWS_SECRET_ACCESS_KEY',
                    description : 'AWS Secret Access Key',
                    required    : true,
                },
                {
                    name        : 'AWS_BUCKET',
                    description : 'AWS Bucket',
                    required    : false,
                    default     : result.HOST,
                }
            ], (err, extra_result) => {
                Object.assign(result, extra_result)
                updatePackageJSON(package_json_path, result)
            })
        } else {
            ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_BUCKET'].forEach( (prop) => {
                result[prop] = ''
            })
            updatePackageJSON(package_json_path, result)
        }
    })

}