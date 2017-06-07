
// Singleton to track the presence of a build error. Separate from the normal
// flow so it’s available even if there was an error before the rest of the
// develop machinery was activated.
module.exports = {
    error: null
}
