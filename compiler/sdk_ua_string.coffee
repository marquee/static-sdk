# Export the base User Agent the SDK uses when requesting data from the
# Marquee API (or anywhere else).
{ name, version } = require '../package.json'
module.exports = "#{ name }/#{ version }"