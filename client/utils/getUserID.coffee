
CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('')
generateID = (n=6) ->
    return "#{ Math.floor(Date.now() / 1000) }_#{ randomChars(n) }"

randomChars = (n) ->
    str = ''
    while str.length < n
        str += CHARS[Math.floor(Math.random() * CHARS.length)]
    return str

had_ls_error = false

E_PRIVATE = 'PRIVATE'
E_DNT = 'DNT'
E_NOLS = 'NOLS'

# Lazily load a unique ID for the current user, or generate one if not
# previously generated. The ID is stored using localStorage, so it won't
# necessarily be one ID per person, or even persist between sessions. However,
# it provides a reasonably persistent method to identify events belonging to
# a particular user within one session, and likely more.
module.exports = (id_key='Marquee.user_id', null_if_error=false) ->
    unless window.localStorage?
        current_id = E_NOLS
    if window.navigator.doNotTrack is 'yes'
        current_id = E_DNT
    if had_ls_error
        current_id = E_PRIVATE
    unless current_id
        current_id = window.localStorage.getItem(id_key)
        unless current_id
            current_id = generateID()
            try
                window.localStorage.setItem(id_key, current_id)
            catch e
                console.info('generateID: in private mode.')
                had_ls_error = true
                current_id = E_PRIVATE
    if null_if_error and (current_id in [E_NOLS, E_DNT, E_PRIVATE] or not current_id)
        return null
    return current_id

module.exports.generateID = generateID
module.exports.randomChars = randomChars