
###
Example required entry structure.

entry =
    social:
        twitter:
            creator
            image
            site
            card
            description
        facebook:
            description
            image

If no image, defaults to summary card. Otherwise, uses summary_large_image.
(Both require separate approval by the Twitter Card system.)

###


_pluckImageURL = (obj) ->
    return obj?.content?['640']?.url or obj

module.exports = (entry) ->

    meta =
        'twitter:site'          : entry.social?.twitter?.site or global.config.TWITTER.site
        'twitter:url'           : entry.full_link
        'twitter:description'   : entry.social?.twitter?.description or entry.content_preview
        'og:type'               : 'article'
        'og:title'              : entry.title
        'og:description'        : entry.social?.facebook?.description or entry.content_preview

    twitter_image = entry.social?.twitter?.image or entry.cover_image
    if twitter_image
        meta['twitter:image'] = _pluckImageURL(twitter_image)
        meta['twitter:card'] = 'summary_large_image'
    else
        meta['twitter:card'] = 'summary'

    if entry.social?.twitter?.creator
        meta['twitter:creator'] = entry.social.twitter.creator

    og_image = entry.social?.facebook?.image or entry.cover_image
    if og_image
        meta['og:image'] = _pluckImageURL(og_image)

    return meta