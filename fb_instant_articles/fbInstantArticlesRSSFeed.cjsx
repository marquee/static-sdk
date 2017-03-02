_               = require 'lodash'
InstantEntry    = require './InstantEntry'
React           = require 'react'
ReactDOM        = require 'react-dom'
ReactDOMServer  = require 'react-dom/server'
rfc822Date      = require 'rfc822-date'
sdk_package     = require '../package.json'

renderItemBody = (entry) ->
    item_body = ReactDOMServer.renderToStaticMarkup(<InstantEntry entry=entry />)
    return """<![CDATA[
        <!doctype html>
        #{ item_body }
    ]]>"""


rssTemplate = _.template """
    <rss xmlns:content='http://purl.org/rss/1.0/modules/content/' xmlns:atom='http://www.w3.org/2005/Atom' version='2.0'>
        <channel>
            <title><%- title %></title>
            <link><%- full_link %></link>
            <description></description>
            <atom:link href="<%- full_link %>" rel="self" />
            <docs>http://www.rssboard.org/rss-specification</docs>
            <generator>proof-sdk/<%- proof_version %></generator>
            <language><%- language %></language>
            <lastBuildDate><%- last_build_date %></lastBuildDate>
            <%= entries %>
        </channel>
    </rss>
"""

entryTemplate = _.template """
    <item>
        <title><%- title %></title>
        <link><%- full_link %></link>
        <description><%- meta_description %></description>
        <guid isPermaLink="false"><%- guid %></guid>
        <pubDate>
            <%- date %>
        </pubDate>
        <content:encoded>
            <%= body %>
        </content:encoded>
    </item>
"""

module.exports = ({ title, entries, language }) ->
    language ?= 'en-us'
    full_link = "http://#{ global.config.HOST }/fb_instant_feed.xml"

    last_build_date = new Date(0)
    _entries = []
    # FB Instant Articles only looks at the up to 100 articles.
    entries = [entries...]
    entries.sort (a,b) -> b.modified_date - a.modified_date
    entries = entries[0...100]

    entries.forEach (entry) ->
        _entries.push entryTemplate
            body                : renderItemBody(entry)
            date                : rfc822Date(entry.first_released_date)
            full_link           : entry.full_link
            guid                : entry.id
            meta_description    : entry.meta_description
            title               : entry.title
        if entry.modified_date > last_build_date
            last_build_date = entry.modified_date

    entries = _entries.join('')
    last_build_date = rfc822Date(last_build_date)
    proof_version = sdk_package.version

    rssTemplate({ title, entries, language, full_link, last_build_date, proof_version })

