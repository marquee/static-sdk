# Export the base User Agent the SDK uses when requesting data from the
# Marquee API (or anywhere else).
{ version } = require '../package.json'
module.exports = "marquee-static-sdk/#{ version }"