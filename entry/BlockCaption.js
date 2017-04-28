// @flow

const React = require('react')
const r = React.createElement

const BlockCaption = (props/* : { plain: ?boolean, caption: ?string, credit: ?string } */) => (
    r('figcaption', { className: props.plain ? null : '_Caption' },
        r('p', { className: props.plain ? null : '_CaptionText' }, props.caption),
        r('p', { className: props.plain ? null : '_Credit' }, props.credit)
    )
)

module.exports = BlockCaption