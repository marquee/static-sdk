React = require 'react'

# Required individually for smaller browserification
Card        = require '../components/Card'
Cover       = require '../components/Cover'
Info        = require '../components/Info'
Title       = require '../components/Title'
Byline      = require '../components/Byline'
DateTime    = require '../components/DateTime'
Summary     = require '../components/Summary'

module.exports = React.createClass
    displayName: 'CoverCard'
    render: ->
        date = @props.item.display_date
        unless date
            date = @props.item.published_date
        <Card className='CoverCard' link=@props.item.link>
            <Cover image=@props.item.cover_image>
                <Info>
                    <Title title=@props.item.title />
                    <Byline byline=@props.item.byline />
                    <DateTime date=date />
                    <Summary summary=@props.item.summary />
                </Info>
            </Cover>
        </Card>
