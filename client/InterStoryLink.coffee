
module.exports = ->
    inter_story_links = document.querySelectorAll('.InterStoryLink')

    checkLinkVisibility = ->
        if window.pageYOffset > window.innerHeight
            for link in inter_story_links
                link.dataset.visible = true
        else
            for link in inter_story_links
                link.dataset.visible = false

    if inter_story_links.length > 0
        window.addEventListener('scroll', checkLinkVisibility)
