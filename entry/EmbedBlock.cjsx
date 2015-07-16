React = require 'react'

querystring     = require 'querystring'
url             = require 'url'
UglifyJS        = require 'uglify-js'

{ Classes } = require 'shiny'
module.exports = React.createClass
    displayName: 'EmbedBlock'

    propTypes:
        block: React.PropTypes.object.isRequired

    render: ->
        unless @props.block.content
            return null

        layout = @props.block.layout or {}
        size = layout.size or 'medium'
        position = layout.position or 'center'

        credit = @props.block.credit
        caption = @props.block.caption
        unless caption
            if @props.block.annotations
                for anno in @props.block.annotations
                    if anno.type is 'caption'
                        caption = anno.content
                        break

        variants = new Classes()
        variants.set('size', size)
        unless size is 'full'
            variants.set('position', position)

        embed_video_url = parseVideoURL(@props.block.content)
        embed_id = "#{ @props.block.id }_content"
        if embed_video_url
            embed = <iframe
                        id              = embed_id
                        className       = '_EmbedFrame'
                        data-frame_src  = embed_video_url
                        frameBorder     = 0
                        webkitAllowFullScreen
                        mozallowfullscreen
                        allowFullScreen
                    />
        else
            embed = <div id=embed_id data-inner_html=@props.block.content />

        <figure
            id          = @props.block.id
            className   = "Block EmbedBlock #{ variants }"
        >
            <div className='_Content'>
                <div className='_EmbedWrapper'>
                    {embed}
                    <script dangerouslySetInnerHTML={__html: UglifyJS.minify("""
                        (function(window){
                            window.addEventListener('load', function(){
                                var target = document.getElementById('#{ embed_id }');
                                if (target) {
                                    if (target.dataset.frame_src) {
                                        target.setAttribute('src', target.dataset.frame_src);
                                    } else if (target.dataset.inner_html) {
                                        target.innerHTML = target.dataset.inner_html;
                                    }
                                }
                            });
                        })(window);
                    """, fromString: true).code} />
                </div>
                {
                    if caption or credit
                        <figcaption className='_Caption'>
                            <span className='_CaptionText'>{caption}</span>
                            <span className='_Credit'>{credit}</span>
                        </figcaption>
                }
            </div>
        </figure>



parseVideoURL = (_url) ->
    parsed_url = url.parse(_url)
    query = querystring.parse(parsed_url.query)

    unless parsed_url.hostname
        return null

    switch parsed_url.hostname.replace('www.','')
        when 'youtube.com'
            return "http://www.youtube.com/embed/#{ query.v }?modestbranding=1"
        when 'youtu.be'
            return "http://www.youtube.com/embed#{ parsed_url.pathname }?modestbranding=1"
        when 'vimeo.com'
            return "http://player.vimeo.com/video#{ parsed_url.pathname }"
        else
            console.error("Unknown video host: #{ parsed_url.hostname }")
    return
