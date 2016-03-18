React           = require 'react'
UglifyJS        = require 'uglify-js'
{ Classes }     = require 'shiny'


num_instances   = 0



EMAIL       = 'email'
FACEBOOK    = 'facebook'
LINKEDIN    = 'linkedin'
PINTEREST   = 'pinterest'
POCKET      = 'pocket'
TWITTER     = 'twitter'
HORIZONTAL  = 'horizontal'
VERTICAL    = 'vertical'



SERVICE_PROPER_NAMES = Object.freeze
    facebook    : 'Facebook'
    twitter     : 'Twitter'
    pinterest   : 'Pinterest'
    linkedin    : 'LinkedIn'
    pocket      : 'Pocket'
    email       : 'Email'



WINDOW_OPTIONS = ("#{ k }=#{ v }" for k,v of {
        scrollbars  : 'yes'
        resizable   : 'yes'
        toolbar     : 'no'
        location    : 'yes'
        width       : 550
        height      : 420
    }).join(',')



ICONS = Object.freeze

    facebook: <svg className='_Icon' width='1em' height='1em' viewBox='0 0 9 18' dangerouslySetInnerHTML={ __html: """
            <g stroke='none' stroke-width='1' fill-rule='evenodd'>
                <path d='M5.85161575,17.6 L5.85161575,8.79896959 L8.45499593,8.79896959 L8.8,5.76608576 L5.85161575,5.76608576 L5.85603889,4.2480982 C5.85603889,3.45707536 5.9365767,3.03322727 7.15404304,3.03322727 L8.7815703,3.03322727 L8.7815703,0 L6.17782156,0 C3.05030056,0 1.94949422,1.47127496 1.94949422,3.94549675 L1.94949422,5.76642924 L0,5.76642924 L0,8.79931303 L1.94949422,8.79931303 L1.94949422,17.6 L5.85161575,17.6 L5.85161575,17.6 L5.85161575,17.6 L5.85161575,17.6 Z' />
            </g>
            """} />

    linkedin: <svg className='_Icon' width='1em' height='1em' viewBox='0 0 18 18' dangerouslySetInnerHTML={ __html: """
            <g stroke='none' stroke-width='1' fill-rule='evenodd'>
                <path d='M0,5.6944383 L0,17.3265467 L3.76806805,17.3265467 L3.76806805,5.6944383 L0,5.6944383 Z M2.13175699,0 C0.842724649,0 0,0.868688876 0,2.00920974 C0,3.12610647 0.817816902,4.01980913 2.0828445,4.01980913 L2.1069245,4.01980913 C3.42078934,4.01980913 4.23905774,3.12610647 4.23905774,2.00920974 C4.21460149,0.868688876 3.42078934,0 2.13175699,0 Z M13.261537,5.6944383 C11.2609408,5.6944383 10.3652401,6.82345591 9.86512868,7.61548214 L9.86512868,5.96789155 L6.09660913,5.96789155 C6.14627413,7.05938847 6.09660913,17.6 6.09660913,17.6 L9.86512868,17.6 L9.86512868,11.103671 C9.86512868,10.7560256 9.88958493,10.4092294 9.98921591,10.1603267 C10.2615456,9.46580798 10.8816056,8.74673864 11.9226139,8.74673864 C13.2866705,8.74673864 13.831932,9.81337617 13.831932,11.3765066 L13.831932,17.5996912 L17.5998495,17.5996912 L17.6,10.9301957 C17.6,7.3573151 15.7410995,5.6944383 13.261537,5.6944383 Z' />
            </g>
        """} />

    email: <svg className='_Icon' width='1em' height='1em' viewBox='0 0 20 13' dangerouslySetInnerHTML={ __html: """
            <g stroke='none' stroke-width='1' fill-rule='evenodd'>
                <path d='M19.2,11.971739 L19.2,0 L12.2103,6.77143309 L19.2,11.971739 Z M0,11.971739 L6.98955,6.77070494 L0,0 L0,11.971739 Z M7.9312125,7.68379443 L0,12.8 L19.2,12.8 L11.2686,7.68379443 L9.6,9.30006637 L7.9312125,7.68379443 Z M0.576,0 L9.6,7.24650498 L18.624,0 L0.576,0 Z' />
            </g>
        """} />

    pinterest: <svg className='_Icon' width='1em' height='1em' viewBox='0 0 16 20' dangerouslySetInnerHTML={ __html: """
            <g stroke='none' stroke-width='1' fill-rule='evenodd'>
                <path d='M8.32857143,0 C10.4866667,0 12.2571429,0.64894932 13.64,1.94684796 C15.0228571,3.2447466 15.7142857,4.77956325 15.7142857,6.5512979 C15.7142857,8.83807169 15.127619,10.723115 13.9542857,12.2064277 C12.7809524,13.6897404 11.272381,14.4313968 9.42857143,14.4313968 C8.82095238,14.4313968 8.2447619,14.2871858 7.7,13.9987639 C7.1552381,13.710342 6.77809524,13.3704162 6.56857143,12.9789864 C6.12857143,14.7507211 5.85619048,15.8014009 5.75142857,16.131026 C5.41619048,17.3259168 4.71428571,18.5826123 3.64571429,19.9011125 C3.52,20.0247219 3.43619048,20.0041203 3.39428571,19.8393078 C3.14285714,18.0881747 3.15333333,16.6357643 3.42571429,15.4820766 L4.90285714,9.20889988 C4.65142857,8.73506386 4.52571429,8.13761846 4.52571429,7.41656366 C4.52571429,6.57189946 4.74571429,5.86629584 5.18571429,5.29975278 C5.62571429,4.73320972 6.16,4.4499382 6.78857143,4.4499382 C7.29142857,4.4499382 7.67904762,4.60960033 7.95142857,4.9289246 C8.22380952,5.24824887 8.36,5.65512979 8.36,6.14956737 C8.36,6.45859085 8.30238095,6.83456943 8.18714286,7.27750309 C8.07190476,7.72043675 7.92,8.2354759 7.73142857,8.82262052 C7.54285714,9.40976514 7.40666667,9.87845076 7.32285714,10.2286774 C7.17619048,10.8261228 7.29142857,11.3463123 7.66857143,11.789246 C8.04571429,12.2321796 8.54857143,12.4536465 9.17714286,12.4536465 C10.2457143,12.4536465 11.1257143,11.8562011 11.8171429,10.6613103 C12.5085714,9.46641945 12.8542857,8.02430985 12.8542857,6.33498146 C12.8542857,5.03708282 12.43,3.98125258 11.5814286,3.16749073 C10.7328571,2.35372888 9.54380952,1.94684796 8.01428571,1.94684796 C6.29619048,1.94684796 4.90809524,2.48763906 3.85,3.56922126 C2.79190476,4.65080346 2.26285714,5.94355171 2.26285714,7.44746601 C2.26285714,8.33333333 2.5247619,9.08529048 3.04857143,9.70333745 C3.21619048,9.90935311 3.26857143,10.1153688 3.20571429,10.3213844 C3.1847619,10.3625876 3.15857143,10.4707458 3.12714286,10.6458591 C3.09571429,10.8209724 3.06952381,10.9445818 3.04857143,11.0166873 C3.02761905,11.0887927 2.98571429,11.196951 2.92285714,11.3411619 C2.86,11.4853729 2.78666667,11.552328 2.70285714,11.5420272 C2.61904762,11.5317264 2.51428571,11.526576 2.38857143,11.526576 C0.796190476,10.8879275 0,9.4355171 0,7.16934487 C0,5.35640709 0.743809524,3.70828183 2.23142857,2.2249691 C3.71904762,0.741656366 5.75142857,0 8.32857143,0 L8.32857143,0 Z' />
            </g>
        """} />

    pocket: <svg className='_Icon' width='1em' height='1em' viewBox='0 0 20 18' dangerouslySetInnerHTML={ __html: """
            <g stroke='none' stroke-width='1' fill-rule='evenodd'>
                <path d='M17.3750739,1.77635684e-15 C18.8235762,1.77635684e-15 20,1.14809418 20,2.56434012 L20,9.66642906 C20,9.7982865 19.9898065,9.92782578 19.9701472,10.0543349 C19.989927,10.2437107 20,10.4350907 20,10.6282051 C20,14.6995352 15.5228477,18 10,18 C4.47715226,18 -1.77635684e-15,14.6995352 -1.77635684e-15,10.6282051 C-1.77635684e-15,10.4350742 0.0100747524,10.2436779 0.0298579047,10.0542863 C0.0101959,9.92779788 -1.77635684e-15,9.79827546 -1.77635684e-15,9.66642906 L-1.77635684e-15,2.56434012 C-1.77635684e-15,1.1485356 1.17521943,1.77635684e-15 2.62492607,1.77635684e-15 L17.3750739,1.77635684e-15 L17.3750739,1.77635684e-15 Z M5.74556083,5.3205615 L10,9.44409486 L14.2544392,5.3205615 C14.7729035,4.81804992 15.6146316,4.81914648 16.1321348,5.3207265 C16.6506932,5.82332922 16.6516477,6.63728406 16.1323051,7.14064692 L10.9678334,12.1462118 C10.7055271,12.4004471 10.3604766,12.5257767 10.0165319,12.522605 C9.66194292,12.5344047 9.30336349,12.4090642 9.03216659,12.1462118 L3.86769493,7.14064692 C3.3492306,6.63813534 3.35036197,5.82230652 3.86786517,5.3207265 C4.38642353,4.81812378 5.2262182,4.81719864 5.74556083,5.3205615 L5.74556083,5.3205615 Z' />
            </g>
        """} />

    twitter: <svg className='_Icon' width='1em' height='1em' viewBox='0 0 18 16' dangerouslySetInnerHTML={ __html: """
            <g stroke='none' stroke-width='1' fill-rule='evenodd'>
                <path d='M8.74580431,4.44343798 L8.7839552,5.10088086 L8.14810666,5.02037767 C5.83361802,4.71178201 3.81161968,3.66524029 2.09482863,1.90758696 L1.25550855,1.03546885 L1.03932008,1.67949449 C0.581509123,3.11513506 0.873999426,4.63127882 1.82777223,5.65098609 C2.33645106,6.21450855 2.22199834,6.2950118 1.34452737,5.95958175 C1.03932008,5.8522441 0.772263684,5.77174091 0.746829718,5.81199253 C0.657810959,5.90591295 0.963018245,7.12687822 1.20464068,7.60989749 C1.53528193,8.2807576 2.20928135,8.93820041 2.94686563,9.32729926 L3.56999719,9.63589492 L2.83241291,9.64931208 C2.12026254,9.64931208 2.09482863,9.66272931 2.17113047,9.94449051 C2.42546988,10.8166086 3.43011056,11.7423955 4.54920396,12.1449115 L5.33765611,12.4266728 L4.6509397,12.8560232 C3.63358204,13.4732145 2.4381868,13.8220617 1.24279157,13.8488961 C0.670527882,13.8623133 0.2,13.9159821 0.2,13.9562337 C0.2,14.0904057 1.7514704,14.841769 2.65437533,15.1369474 C5.36309008,16.0090656 8.58048365,15.6333839 10.9967081,14.1440746 C12.7134991,13.0841156 14.4302902,10.9776151 15.2314593,8.93820041 C15.6638363,7.85140712 16.0962133,5.86566133 16.0962133,4.91304002 C16.0962133,4.29584877 16.1343643,4.21534558 16.8465146,3.47739951 C17.2661747,3.04804904 17.6604008,2.578447 17.7367025,2.44427496 C17.8638722,2.18934816 17.8511553,2.18934816 17.2025898,2.41744056 C16.1216473,2.81995664 15.9690436,2.76628784 16.5031564,2.16251376 C16.8973825,1.73316329 17.3679104,0.954965656 17.3679104,0.726873189 C17.3679104,0.686621625 17.1771558,0.753707649 16.9609674,0.874462402 C16.7320619,1.00863445 16.223383,1.20989246 15.8418739,1.33064727 L15.1551575,1.55873968 L14.5320259,1.11597204 C14.1886677,0.874462402 13.7054228,0.606118435 13.4510834,0.525615182 C12.8025179,0.337774405 11.8105942,0.364608802 11.2256135,0.579283975 C9.6359922,1.18305806 8.63135152,2.73945345 8.74580431,4.44343798 C8.74580431,4.44343798 8.63135152,2.73945345 8.74580431,4.44343798 L8.74580431,4.44343798 L8.74580431,4.44343798 Z' />
            </g>
        """} />



buildLinkFor = (entry, service) ->
    link    = encodeURIComponent(entry.full_link)
    if entry.cover_image
        cover   = encodeURIComponent(entry.cover_image.toString())
    else
        cover = ''
    title   = encodeURIComponent(entry.title)
    summary = encodeURIComponent(entry.summary)

    switch service
        # https://developer.linkedin.com/documents/share-linkedin
        when LINKEDIN
            return "http://www.linkedin.com/shareArticle?mini=true&url=#{link}&title=#{title}&summary=#{summary}"
        when FACEBOOK
            return "http://www.facebook.com/sharer/sharer.php?s=100&p[url]=#{link}&p[images][0]=#{cover}&p[title]=#{title}&p[summary]=#{summary}"
        when TWITTER
            return "http://twitter.com/home?status=#{title}%20%E2%80%93%20#{link}"
        when PINTEREST
            return "http://www.pinterest.com/pin/create/button/?url=#{link}&media=#{cover}&description=#{title}"
        when POCKET
            return "https://getpocket.com/edit.php?url=#{link}"
        when EMAIL
            body = """
                #{ entry.title }
                #{ if entry.byline then "by #{ entry.byline }" else '' }

                #{ entry.summary or '' }

                #{ entry.full_link }
            """
            body = encodeURIComponent(body)
            return "mailto:?subject=#{ title }&body=#{ body }"

    return null



module.exports = React.createClass
    displayName: 'ShareEntry'

    propTypes:
        services: (props, prop_name, component_name) ->
            for service in props[prop_name]
                unless service in [
                    LINKEDIN
                    FACEBOOK
                    TWITTER
                    PINTEREST
                    POCKET
                    EMAIL
                ]
                    return new Error('')
        entry: React.PropTypes.shape
            id          : React.PropTypes.string.isRequired
            full_link   : React.PropTypes.string.isRequired
            cover_image : React.PropTypes.oneOfType([
                    React.PropTypes.string
                    React.PropTypes.object
                ])
            title       : React.PropTypes.string.isRequired
            summary     : React.PropTypes.string
        icon        : React.PropTypes.bool.isRequired
        greyscale   : React.PropTypes.bool.isRequired
        border      : React.PropTypes.bool.isRequired
        layout      : React.PropTypes.oneOf([HORIZONTAL, VERTICAL])
        label       : React.PropTypes.string

    getDefaultProps: -> {
        icon        : true
        greyscale   : false
        layout      : VERTICAL
        label       : 'Share'
        border      : false
    }

    getInitialState: ->
        num_instances += 1
        return {
            id: "#{ @props.entry.id }-ShareEntry--#{ num_instances }"
        }

    render: ->
        _cx = new Classes('ShareEntry', @props.className)
        _cx.set('layout'    , @props.layout)
        _cx.add('greyscale' , @props.greyscale)
        _cx.add('border'    , @props.border)

        <div className=_cx id=@state.id>
            {
                if @props.label
                    <span className='_Label'>
                        { @props.label }
                    </span>
            }
            <div
                className = '_Services'
            >
                {
                    @props.services.map (service) =>
                        _popup = service isnt EMAIL
                        cx = new Classes('_ShareLink')
                        cx.set('service'    , service)
                        cx.add('icon'       , @props.icon)
                        service_id = "#{ @state.id }--#{ service }"
                        <a
                            href        = { buildLinkFor(@props.entry, service) }
                            className   = cx
                            target      = { if _popup then '_blank' else null }
                            tabIndex    = 0
                            key         = service
                            aria-label  = "Share #{ @props.entry.title } on #{ SERVICE_PROPER_NAMES[service] }"
                            id          = service_id
                        >
                            {
                                if @props.icon
                                    ICONS[service]
                                else
                                    <span className='_Label'>
                                        { SERVICE_PROPER_NAMES[service] }
                                    </span>
                            }
                            {
                                if _popup
                                    <script dangerouslySetInnerHTML={__html: UglifyJS.minify("""
                                        (function (window) {
                                            window.addEventListener('load', function () {
                                                var link_el = document.getElementById('#{ service_id }');
                                                if (link_el) {
                                                    link_el.addEventListener('click', function (e) {
                                                        e.preventDefault();
                                                        window.open(link_el.href, 'intent', '#{ WINDOW_OPTIONS }');
                                                    });
                                                }
                                            });
                                        })(window);
                                    """, fromString: true).code} />
                            }
                        </a>
                }
            </div>
        </div>


module.exports.EMAIL        = EMAIL    
module.exports.FACEBOOK     = FACEBOOK 
module.exports.LINKEDIN     = LINKEDIN 
module.exports.PINTEREST    = PINTEREST
module.exports.POCKET       = POCKET   
module.exports.TWITTER      = TWITTER 
module.exports.HORIZONTAL   = HORIZONTAL
module.exports.VERTICAL     = VERTICAL

