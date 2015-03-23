React = require 'react'

# Required individually for smaller browserification.
Card        = require '../components/Card'
Cover       = require '../components/Cover'
Info        = require '../components/Info'
Title       = require '../components/Title'
Byline      = require '../components/Byline'
DateTime    = require '../components/DateTime'
Summary     = require '../components/Summary'

module.exports = React.createClass
    displayName: 'SummaryCard'

    propTypes:
        item: React.PropTypes.object.isRequired

    render: ->
        date = @props.item.display_date
        unless date
            date = @props.item.published_date
        <Card className='SummaryCard'>
            <Cover image=@props.item.cover_image link=@props.item.link />
            <Info>
                <Title title=@props.item.title link=@props.item.link />
                <Byline byline=@props.item.byline />
                <DateTime date=date />
                <Summary summary=@props.item.summary />
            </Info>
        </Card>