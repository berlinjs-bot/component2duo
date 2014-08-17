fs = require 'fs'
path = require 'path'
requires = require 'requires'

debug = require('debug')('component2duo')


class Converter
    STYLE = [0,1]
    @ABSOLUTE: STYLE[0]
    @RELATIVE = STYLE[1]

    constructor: (@rootPath, @style = ABSOLUTE, opt = {}) ->
        unless @style in STYLE
            throw new Error 'style should either be "absolute" or "relative"'

        @simulate = opt.simulate or true
        @cwd = process.cwd()
        debug "cwd is #{@cwd}"
        @localsMap = {}
        # flatten map like this:
        # localName: {
        #   absPath: "/app/lib/local1"
        #   scripts: ["inde.js", "foo/bar.js"]
        # } 
        @rootManifest = opt.rootManifest or 'component.json'
        @localManifest = opt.localManifest or 'component.json'
        unless @rootPath? or @rootPath is ''
            throw new Error 'no root path was given'

    start: ->
        
        fullPath = path.join @rootPath, @rootManifest
        debug "starting at #{fullPath}"
        r = require path.join @cwd, fullPath
        debug "root component.json - ok"
        @lookupPath = r.paths or r.path
        if @lookupPath.length is 0
            throw new Error 'need a lookup path for locals'
        # TODO: add support for multiple lookup paths
        if @lookupPath.length > 1
            throw new Error 'multiple paths not implemented' 
        @lookupPath = @lookupPath[0]

        @rootLocals =  r.locals or r.locals

        debug "traversing locals for paths: #{@lookupPath}"
        @traverseLocals @rootLocals
        debug "finished traversing"

        debug "map:", @localsMap
        simulateContainer = {}

        for localName, {absPath, scripts} of @localsMap
            debug "analyze #{localName}"
            for script in scripts
                debug "file #{script}"
                componentPath = path.join absPath, script
                filePath = path.join @cwd, @rootPath, componentPath
                newContent = @rewriteRequire componentPath, filePath

                if @simulate
                    simulateContainer[localName] ?= {}
                    simulateContainer[localName][script] = newContent
                else
                    console.log "//fs.writeFileSync..."
                    #fs.writeFileSync filePath, newContent

        return simulateContainer

    traverseLocals: (locals) ->
        for local in locals
            continue if @localsMap[local]
            debug "traverse '#{local}'"
            manifestPath = path.join @lookupPath, local, @localManifest
            manifest = require path.join @cwd, @rootPath, manifestPath
            debug "found manifest"
            @localsMap[local] = 
                scripts: manifest.scripts
                absPath: path.dirname manifestPath
            debug "locals: #{manifest.locals}"
            @traverseLocals manifest.locals if manifest.locals?.length > 0
            return

    rewriteRequire: (scriptPath, fullPath) ->
 
        currentDir = path.dirname scriptPath
        content = fs.readFileSync fullPath, 'utf8'
        newContent = requires content, (require) =>
            # remain quote
            quote = if require.string.match(/"/) then '"' else "'"

            # check if the require is relative, remote or local
            # requireRoot is the local name
            [requireRoot, rest...] = require.path.split('/')
            if requireRoot is ''
                throw new Error "cannot handle require path: #{require.path}"
            if requireRoot is '.' or requireRoot is '..'
                #ignore relative paths, don't replace anything
                debug "ignore relative require path: '#{require.path}'"

            else if @localsMap[requireRoot]?
                {absPath} = @localsMap[requireRoot]

                if @style is STYLE[0]
                    newRequire = '/' + absPath
                    newRequire += '/' + rest.join('/') if rest.length > 0 
                else
                    newRequire = path.relative currentDir, absPath
                    newRequire += '/' + rest.join('/') if rest.length > 0 
                    
                debug "convert from '#{require.path}' -> '#{newRequire}'"
                return "require(#{quote}#{newRequire}#{quote})"
            else
                debug "ignore remote require: '#{requireRoot}'"
                
            # remain old
            return "require(#{quote}#{require.path}#{quote})"

        return newContent

module.exports = Converter

if require.main is module
    debug "starting main..."
    rootPath = process.argv[2]
    style = parseInt process.argv[3]

    converter = new Converter rootPath, style
    console.log converter.start()