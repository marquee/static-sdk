# Export the base User Agent the SDK uses when requesting data from the
# Marquee API (or anywhere else).
{ version } = require '../_package_data'
module.exports = "marquee-static-sdk/#{ version }"