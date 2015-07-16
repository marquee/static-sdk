React = require 'react'

module.exports = React.createClass
    displayName: 'BuildInfo'
    render: ->
        build_info =
            commit          : global.build_info.commit
            assets          : global.build_info.asset_hash
            publication     : global.config.PUBLICATION_SHORT_NAME
            env             : process.env.NODE_ENV
        <script
            id      = '_build_info'
            type    = 'application/json'
            dangerouslySetInnerHTML = {
                __html: JSON.stringify(build_info)
            }
        />