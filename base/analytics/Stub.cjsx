React = require 'react'

UglifyJS = require 'uglify-js'

_rawScript = require './_rawScript'

module.exports = React.createClass
    displayName: 'Stub'
    render: ->
        # Assemble the page-specific tracking script.
        stub_script = """
        (function(window, document, navigator, screen, performance, localStorage){
            var view_start = new Date();
            var CHARS   = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('')
            var ID_KEY  = 'Marquee.user_id';
            var URL     = 'http://stubs#{ if process.env.NODE_ENV isnt 'production' then '.staging' else '' }.marquee.pub';

            function generateID (n) {
                return Math.floor(Date.now() / 1000) + '_' + randomChars(n);
            }

            function randomChars (n) {
                var str = '';
                while (str.length < n) {
                    str += CHARS[Math.floor(Math.random() * CHARS.length)];
                }
                return str;
            }

            function getUserID () {
                var current_id;
                if (!localStorage) {
                    return null;
                }
                if (navigator.doNotTrack === 'yes') {
                    return null;
                }
                current_id = localStorage.getItem(ID_KEY);
                if (!current_id) {
                    current_id = generateID(6);
                    try {
                        localStorage.setItem(ID_KEY, current_id);
                    }
                    catch (e) {
                        return null;
                    }
                }
                return current_id;
            }

            function makePayload (from_blur) {
                var track_start = new Date();
                var data = {
                    date: view_start
                }
                if (from_blur !== null) {
                    if (from_blur) {
                        data.ms_in_background = track_start - view_start;
                    } else {
                        data.ms_in_background = -1;
                    }
                } else {
                    data.ms_in_background = null;
                }

                if (performance) {
                    var _nav_data = performance.navigation;
                    var _timing_data = performance.timing;
                    if (_nav_data && _timing_data) {
                        var _nav_start = _timing_data.navigationStart;
                    }
                    data.timing = {
                        nav_type    : _nav_data.type,
                        req_start   : _timing_data.requestStart - _nav_start,
                        res_start   : _timing_data.responseStart   - _nav_start,
                        res_end     : _timing_data.responseEnd     - _nav_start,
                        dom_ready   : _timing_data.domComplete     - _nav_start,
                        dns_end     : _timing_data.domainLookupEnd - _nav_start
                    }
                }

                var user_id = getUserID();
                var _e_data = {
                    _logv       : 1,
                    publication : '#{ global.config.PUBLICATION_SHORT_NAME }',
                    metric      : 'pageview',
                    data        : data,
                    version     : '#{ global.build_info.commit }',
                    page: {
                        kind                : #{ if @props.kind then "'" + @props.kind + "'" else 'null' },
                        url                 : window.location.href,
                        bytes               : document.documentElement.innerHTML.length,
                        source_content_id   : #{ if @props.source_content_id then "'" + @props.source_content_id + "'" else 'null' }
                    },
                    client: {
                        v_width     : window.innerWidth,
                        v_height    : window.innerHeight,
                        user_id     : user_id,
                        view_id     : user_id + '-' + generateID(3),
                        tz_offset   : track_start.getTimezoneOffset(),
                        referrer    : document.referrer
                    }
                }
                if (navigator.language) {
                    _e_data.client.language = navigator.language.toLowerCase();
                }
                if (screen) {
                    _e_data.client.d_width  = screen.width;
                    _e_data.client.d_height = screen.height;
                    _e_data.client.d_angle = screen.orientation ? screen.orientation.angle : null;
                }
                return _e_data;
            }

            function sendRequest (payload) {
                var url = URL + '?pv=' + btoa(JSON.stringify(payload));
                var xhr = new XMLHttpRequest();
                xhr.open('get', url);
                xhr.setRequestHeader('Accept', 'text/html');
                xhr.send();
            }

            function trackPageview (from_blur) {
                sendRequest(
                    makePayload(from_blur)
                );
            }

            function trackDNT () {
                // Ironic, yes. Doesn't record anything except that DNT is
                // set so we have an idea of how common this is.
                sendRequest({ do_not_track: true });
            }

            function startTrack () {
                if (navigator.doNotTrack === 'yes') {
                    trackDNT();
                    return;
                }
                if (document.hasFocus) {
                    if (document.hasFocus()) {
                        trackPageview(false);
                    } else {
                        function _fn () {
                            window.removeEventListener('focus', _fn);
                            trackPageview(true);
                        }
                        window.addEventListener('focus', _fn);
                    }
                } else {
                    trackPageview(null);
                }
            }

            if (window.addEventListener) {
                window.addEventListener('load', startTrack);
            } else {
                setTimeout(startTrack, 10);
            }
        })(window, window.document, window.navigator, window.screen, window.performance, window.localStorage);
        """

        if process.env.NODE_ENV is 'production'
            stub_script = UglifyJS.minify(stub_script,
                fromString: true
            ).code

        return _rawScript(stub_script)