React = require 'react'

url             = require 'url'
UglifyJS        = require 'uglify-js'

{ Classes } = require 'shiny'


EmbedCard = (props) ->
    <a className='EmbedCard' href={ props.url }>
        <img src={ props.thumbnail_url } />
        <h1>{ props.title }</h1>
        <p>{ props.description }</p>
    </a>

module.exports = React.createClass
    displayName: 'EmbedBlock'

    getDefaultProps: -> {
        plain: false
    }

    propTypes:
        block   : React.PropTypes.object.isRequired
        plain   : React.PropTypes.bool.isRequired

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

        cx = new Classes('Block EmbedBlock')
        cx.set('size', size)
        unless size is 'full'
            cx.set('position', position)

        embed_id = "#{ @props.block.id }_content"

        embed_video_url = parseVideoURL(@props.block.content)
        if not embed_video_url
            if @props.block.embedly_result
                embed_card = <EmbedCard {... @props.block.embedly_result} />
            else
                embed_markup = @props.block.content
        

        if @props.plain
            if embed_video_url
                embed = <iframe
                            src             = embed_video_url
                            frameBorder     = 0
                            webkitAllowFullScreen
                            mozallowfullscreen
                            allowFullScreen
                        />
            else if embed_card
                embed = embed_card
            else
                embed = <div dangerouslySetInnerHTML={__html: embed_markup} />

            return <figure>
                {embed}
                {
                    if caption or credit
                        <figcaption className='_Caption'>
                            <p>{caption}</p>
                            <p>{credit}</p>
                        </figcaption>
                }
            </figure>
        else
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
            else if embed_card
                embed = embed_card
            else
                embed = <div dangerouslySetInnerHTML={__html: embed_markup} />

        <figure
            id          = @props.block.id
            className   = cx
        >
            <div className='_Content'>
                <div className='_EmbedWrapper'>
                    {embed}
                    {
                        if embed_video_url
                            <script dangerouslySetInnerHTML={__html: UglifyJS.minify("""
                                (function(window){
                                    window.addEventListener('load', function(){
                                        var target = document.getElementById('#{ embed_id }');
                                        if (target) {
                                            target.setAttribute('src', target.dataset.frame_src);
                                        }
                                    });
                                })(window);
                            """, fromString: true).code} />
                    }
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
    parsed_url = url.parse(_url, true)

    unless parsed_url.hostname
        return null

    switch parsed_url.hostname.replace('www.','')
        when 'youtube.com'
            return "//www.youtube.com/embed/#{ parsed_url.query.v }?modestbranding=1"
        when 'youtu.be'
            return "//www.youtube.com/embed#{ parsed_url.pathname }?modestbranding=1"
        when 'vimeo.com'
            return "//player.vimeo.com/video#{ parsed_url.pathname }"
        when 'player.vimeo.com'
            return _url
        else
            console.error("Unknown video host: #{ parsed_url.hostname }")
            return _url
    return

module.exports.parseVideoURL = parseVideoURL
