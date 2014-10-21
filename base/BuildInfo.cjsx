React = require 'react'

module.exports = React.createClass
    displayName: 'BuildInfo'
    render: ->
        build_info =
            date    : global.build_info.date
            commit  : global.build_info.commit
        <script
            id      = '_build_info'
            type    = 'application/json'
            dangerouslySetInnerHTML = {
                __html: JSON.stringify(build_info)
            }
        />