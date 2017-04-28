const SDKError = require('./SDKError')

module.exports = function loadConfiguration (project_package, configuration_name=null) {

    const project_config = {}

    if (null == project_package.proof) {
        throw new SDKError('configuration', 'Project missing `package.proof`.')
    }

    const config_from_package = project_package.proof

    Object.keys(config_from_package).forEach( key => {
        if ('configurations' !== key) {
            project_config[key] = config_from_package[key]
        }
    })

    // Override config with specified configuration values.
    if (configuration_name) {
        if (null == config_from_package.configurations[configuration_name]) {
            const _available_configs = Object.keys(config_from_package.configurations)
                .map(c => `\`${ c }\``)
                .join(', ')
            throw new SDKError('configuration', `Unknown configuration specified: \`${ configuration_name }\`. Package has ${ _available_configs }.`)
        }
        Object.assign(project_config, config_from_package.configurations[configuration_name])
    }

    return project_config
}