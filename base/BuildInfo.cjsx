React = require 'react'

module.exports = React.createClass
    displayName: 'BuildInfo'
    render: ->
        build_info =
            commit  : global.build_info.commit
            assets  : global.build_info.asset_hash
        <script
            id      = '_build_info'
            type    = 'application/json'
            dangerouslySetInnerHTML = {
                __html: JSON.stringify(build_info)
            }
        />