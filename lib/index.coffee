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

        @simulate = opt.simulate or false
        @debugPrint = opt.debug or false
        debug "debug: #{@debugPrint}, simulate: #{@simulate}"

        if @rootPath[0] isnt '/'
            @rootPath = path.join process.cwd(), @rootPath
        debug "root path: #{@rootPath}"
        @rootDir = path.dirname @rootPath
        @localsMap = {}
        # flatten map like this:
        # localName: {
        #   absPath: "/app/lib/local1"
        #   scripts: ["inde.js", "foo/bar.js"]
        # } 
        @localManifest = opt.localManifest or 'component.json'
        unless @rootPath? or @rootPath is ''
            throw new Error 'no root path was given'

    start: ->
        
        fullPath = path.join @rootPath
        debug "starting at #{fullPath}"
        r = require fullPath
        debug "root component.json - ok"
        @lookupPath = r.paths or r.path
        if @lookupPath.length is 0
            throw new Error 'need a lookup path for locals'
        # TODO: add support for multiple lookup paths
        if @lookupPath.length > 1
            throw new Error 'multiple paths not implemented' 
        @lookupPath = @lookupPath[0]

        @rootLocals =  r.locals or r.local

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
                filePath = path.join @rootDir, componentPath
                newContent = @rewriteRequire componentPath, filePath

                if @simulate
                    simulateContainer[localName] ?= {}
                    simulateContainer[localName][script] = newContent
                else
                    fs.writeFileSync filePath, newContent, 'utf8'

        return simulateContainer

    traverseLocals: (locals) ->
        for local in locals
            continue if @localsMap[local]
            debug "traverse '#{local}'"
            # TODO: try catch multiple lookup paths
            manifestPath = path.join @lookupPath, local, @localManifest
            manifest = require path.join @rootDir, manifestPath
            debug "found manifest"
            if manifest.paths?
                console.log "'#{local}': ignore paths: #{manifest.paths}"
            @localsMap[local] = 
                scripts: manifest.scripts
                absPath: path.dirname manifestPath
            transLocals = manifest.locals or manifest.local or []
            debug "locals: #{transLocals}"
            @traverseLocals transLocals if transLocals.length > 0

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
                    
                debugStr = "#{scriptPath}: '#{require.path}' -> '#{newRequire}'"
                debug debugStr
                console.log debugStr if @debugPrint
                return "require(#{quote}#{newRequire}#{quote})"
            else
                debug "ignore remote require: '#{requireRoot}'"
                
            # remain old
            return "require(#{quote}#{require.path}#{quote})"

        return newContent

module.exports = Converter

if require.main is module
    debug "starting main..."
    if process.argv.length < 3
        console.log "usage: rootComponentDir {0|1} [true]"
    rootPath = process.argv[2]
    style = parseInt process.argv[3]
    debugVal = process.argv[4] is 'true'

    converter = new Converter rootPath, style, {debug: debugVal, simulate: debugVal}
    converter.start()