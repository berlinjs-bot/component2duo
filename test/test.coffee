Converter = require '../lib'
{expect} = require 'chai'

{join} = require 'path'

opts = {simulate: true}

fixture = (name) ->
  join 'test/fixtures', name


describe 'component2duo converter', ->

    it 'should convert locals with an absolute style', (done) ->
        simple = fixture 'simple'
        c = new Converter simple, Converter.ABSOLUTE, opts
        result = c.start()
        expect(result.foo['index.js']).contain "require('./script.js')"
        expect(result.foo['script.js']).contain "require('/lib/bar')"
        expect(result.bar['index.js']).contain "require('emitter')"
        done()

    it 'should convert locals with a relative style', (done) ->
        simple = fixture 'simple'
        c = new Converter simple, Converter.RELATIVE, opts
        result = c.start()
        expect(result.foo['index.js']).contain "require('./script.js')"
        expect(result.foo['script.js']).contain "require('../bar')"
        expect(result.bar['index.js']).contain "require('emitter')"
        done()