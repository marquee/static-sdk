jest.autoMockOff()

fs      = require 'fs'
path    = require 'path'
sass    = require 'node-sass'
css     = require 'css'

renderSass = (sass_source) ->
    output = sass.renderSync
                data: """
                    @import "marquee"

                    #{ sass_source }
                """
                indentedSyntax: true
                includePaths: [
                    path.join(__dirname, '..')
                ]

    parsed = css.parse(output.css.toString())
    return parsed

describe 'layout', ->
    describe 'gutter-all', ->
        it 'should use padding by default', ->
            parsed = renderSass """
                .Foo
                    +gutter-all
            """
        
            parsed.stylesheet.rules[0].declarations.forEach (declaration) ->
                expect(declaration.property.split('-')[0]).toEqual('padding')
                expect(declaration.value).toEqual('14px')

            parsed.stylesheet.rules[1...].forEach (mq_rule) ->
                expect(mq_rule.rules[0].declarations[0].property.split('-')[0]).toEqual('padding')
                expect(mq_rule.rules[0].declarations[0].value).toEqual('28px')



        it 'should apply multiplier to default values', ->
            parsed = renderSass """
                .Foo
                    +gutter-all(2)
            """

            parsed.stylesheet.rules[0].declarations.forEach (declaration) ->
                expect(declaration.value).toEqual('28px')

            parsed.stylesheet.rules[1...].forEach (mq_rule) ->
                expect(mq_rule.rules[0].declarations[0].value).toEqual('56px')



        it 'should support using margin', ->
            parsed = renderSass """
                .Foo
                    +gutter-all($padding: false)
            """
        
            parsed.stylesheet.rules[0].declarations.forEach (declaration) ->
                expect(declaration.property.split('-')[0]).toEqual('margin')
                expect(declaration.value).toEqual('14px')

            parsed.stylesheet.rules[1...].forEach (mq_rule) ->
                expect(mq_rule.rules[0].declarations[0].property.split('-')[0]).toEqual('margin')
                expect(mq_rule.rules[0].declarations[0].value).toEqual('28px')


        it 'should accept alternate sizes', ->
            parsed = renderSass """
                .Foo
                    +gutter-all($values: (1em, 2em))
            """
        
            parsed.stylesheet.rules[0].declarations.forEach (declaration) ->
                expect(declaration.property.split('-')[0]).toEqual('padding')
                expect(declaration.value).toEqual('1em')

            parsed.stylesheet.rules[1...].forEach (mq_rule) ->
                expect(mq_rule.rules[0].declarations[0].property.split('-')[0]).toEqual('padding')
                expect(mq_rule.rules[0].declarations[0].value).toEqual('2em')
