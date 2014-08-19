{expect} = require 'chai'
{join} = require 'path'

Converter = require '../lib'
opts = {simulate: true}

fixture = (name) ->
  join 'test/fixtures', name

describe 'absolute path replacemnet', ->

    simple = fixture 'simple'
    c = new Converter simple, Converter.ABSOLUTE, opts
    result = c.start()

    it 'should ignore relative files within a component', (done) ->
        expect(result.foo['index.js']).contain "require('./script.js')"
        done()

    it 'should replace the path of a local component', (done) ->
        expect(result.foo['script.js']).contain "require('/lib/bar')"
        done()

    it 'should remain relative files of a local component', (done) ->
        expect(result.foo['script.js']).contain "require('/lib/bar/qux')"
        done()

    it 'should ignore relative files in a subdirectory', (done) ->
        expect(result.foo['sub/baz.js']).contain "require('../script')"
        done()

    it 'should ignore remote components', (done) ->
        expect(result.bar['index.js']).contain "require('emitter')"
        done()

describe 'relative path replacement', ->

    simple = fixture 'simple'
    c = new Converter simple, Converter.RELATIVE, opts
    result = c.start()

    it 'should remain relative files of a local component', (done) ->
        expect(result.foo['script.js']).contain "require('../bar/qux')"
        done()

    it 'should ignore relative files in a subdirectory', (done) ->
        expect(result.foo['sub/baz.js']).contain "require('../script')"
        done()

describe 'transitive locals', ->

    simple = fixture 'simple'
    c = new Converter simple, Converter.RELATIVE, opts
    result = c.start()

    it.skip 'should be traversed', (done) ->
        done()

describe 'multiple lookup paths', ->

    simple = fixture 'simple'
    c = new Converter simple, Converter.RELATIVE, opts
    result = c.start()

    it.skip 'should work with 2 lookup paths in root component', (done) ->
        done()

    it.skip 'should use inner lookup path within local component', (done) ->
        done()