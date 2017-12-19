// @flow

const React = require('react')
const Shiny = require('shiny')

const r = React.createElement

const SectionBreakBlock = (props) => {
    return(
        r('hr', {className: 'SectionBreakBlock', id:props.block.id})
    )
}

module.exports = SectionBreakBlock
