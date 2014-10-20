React = require 'react'

module.exports = React.createClass
    displayName: 'BuildInfo'
    render: ->
        build_info =
            date: new Date()
            commit: global.CURRENT_COMMIT
        <script
            type    = 'application/json'
            dangerouslySetInnerHTML = {
                __html: JSON.stringify(build_info)
            }
        />