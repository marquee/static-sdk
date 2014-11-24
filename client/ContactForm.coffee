DEFAULT_PIGEONFARM_SERVER = 'https://pigeon-farm.herokuapp.com'
_start = new Date()
_first_focus = null

FIELDS = [
        {
            tag: 'input',
            name: 'name',
            label: 'Name',
            placeholder: '',
        },
        {
            tag: 'input',
            name: 'email',
            type: 'email',
            label: 'Email',
            placeholder: 'name@example.com',
            required: true
        },
        {
            tag: 'input',
            name: 'subject',
            label: 'Subject',
            placeholder: '',
        },
        {
            tag: 'textarea',
            name: 'message',
            label: 'Message',
            placeholder: '',
            required: true
        }
    ]

_validateField = (name, field_el) ->
    console.log 'validating', name, field_el

_clearError = (field_wrapper_el) ->
    console.log 'clearing error state'

class ContactForm
    constructor: (wrapper_el, payload) ->
        @_wrapper   = wrapper_el
        @_url       = payload.url

        @_constructForm()

    _constructForm: ->
        @_fields = {}
        form_el = document.createElement('form')

        FIELDS.forEach (field_spec) =>
            field_wrapper_el = document.createElement('label')
            field_wrapper_el.className = '_Field'
            field_wrapper_el.dataset.required = field_spec.required

            label_el = document.createElement('span')
            label_el.className = '_Label'
            label_el.innerHTML = field_spec.label

            help_el = document.createElement('span')
            help_el.className = '_Help'

            field_el = document.createElement(field_spec.tag)
            if field_spec.type
                field_el.type = field_spec.type
            field_el.className = '_Input'
            if field_spec.tag is 'textarea'
                field_wrapper_el.classList.add('-multiline')
            field_el.placeholder = field_spec.placeholder
            field_el.required = field_spec.required
            field_el.addEventListener('focus', @_recordFocus)
            field_el.addEventListener 'keypress', =>
                window.requestAnimationFrame => @_validateForm(true)
            field_el.addEventListener('blur', @_validateField)

            @_fields[field_spec.name] =
                el: field_el
                help_el: help_el
                spec: field_spec

            field_wrapper_el.appendChild(label_el)
            field_wrapper_el.appendChild(field_el)
            field_wrapper_el.appendChild(help_el)
            form_el.appendChild(field_wrapper_el)

        @_button_el = document.createElement('button')
        @_button_el.className = '_Submit'
        @_button_el.innerHTML = 'Send Message'
        @_button_el.addEventListener('click', @_submitForm)
        @_button_el.disabled = true
        form_el.appendChild(@_button_el)

        @_success_el = document.createElement('div')
        @_success_el.className = '_Success'
        @_success_el.innerHTML = @_wrapper.dataset.success_message
        form_el.appendChild(@_success_el)

        @_wrapper.appendChild(form_el)

    _recordFocus: =>
        _first_focus = new Date()
        for name, field of @_fields
            field.el.removeEventListener('focus', @_recordFocus)

    _validateForm: (soft=false) =>
        is_valid = true
        for name, field of @_fields
            if field.spec.required and not field.el.value
                field.el.dataset.valid = false
                is_valid = false
            else
                field.el.dataset.valid = true
        @_button_el.disabled = not is_valid
        console.log is_valid

    _clearError: (wrapper) =>
        field.el.dataset.valid = true

    _submitForm: (e) =>
        e.preventDefault()

        _now = new Date()
        form =
            time_on_page    : _now - _start
            first_focus     : _now - _first_focus
            referrer        : document.referrer
            page_url        : window.location.href
            commit          : @_wrapper.dataset.commit
            local_tz        : _now.getTimezoneOffset()
        for name, field of @_fields
            form[name] = field.el.value

        xhr = new XMLHttpRequest()
        xhr.onload = =>
            if xhr.status is 201
                @_showSubmitSuccess()
            else
                @_showSubmitError()
        xhr.open('post', @_url, true)
        xhr.setRequestHeader('Content-Type', 'application/javascript')
        xhr.send(JSON.stringify(form))

    _showSubmitSuccess: ->
        console.log 'success!'
        @_wrapper.dataset.success = true

    _showSubmitError: ->
        console.log 'error!'




METADATA = ['time_on_page', 'first_focus', 'referrer', 'page_url', 'commit', 'local_tz']

module.exports = (_field_overrides=null) ->
    if _field_overrides
        FIELDS = _field_overrides
    form_el = document.querySelector('.ContactForm')

    if form_el
        xhr = new XMLHttpRequest()
        xhr.onload = ->
            if xhr.status is 200
                payload = JSON.parse(xhr.responseText)
                new ContactForm(form_el, payload)
            else
                # The Pigeon Farm server is not available, so show the fallback.
                form_el.dataset.fallback_enabled = true
        field_list = FIELDS.map (f) -> f.name
        field_list.push(METADATA...)
        _host = form_el.dataset.host or DEFAULT_PIGEONFARM_SERVER
        _url = "#{ _host }/publications/#{ form_el.dataset.publication }/form.json?fields=#{ field_list.join(',') }"
        xhr.open('get', _url, true)
        xhr.send()
