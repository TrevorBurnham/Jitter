###
    Jitter, a CoffeeScript compilation utility

    The latest version and documentation, can be found at:
    http://github.com/TrevorBurnham/Jitter

    Copyright (c) 2010 Trevor Burnham
    http://iterative.ly

    Based on command.coffee by Jeremy Ashkenas
    http://jashkenas.github.com/coffee-script/documentation/docs/command.html

    Growl notification code contributed by Andrey Tarantsov
    http://www.tarantsov.com/

    SourceMaps support by Aria Minaei
    https://twitter.com/ariaminaei
    https://github.com/AriaMinaei

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.
###

# External dependencies
fs = require 'fs'
path = require 'path'
optparse = require './optparse'
color = require('./ansi-color').set

if path.basename(process.argv[1]) is 'witter'

    targetlib = 'coco'
    target_ext = '.coco'

else

    targetlib = 'coffee-script'
    target_ext = '.coffee'

CoffeeScript =  require targetlib

{exec} = require 'child_process'
{puts, print} = try require 'util' catch e then require 'sys'
{q} = require 'sink'

# Banner shown if jitter is run without arguments
BANNER = '''
    Jitter takes a directory of *.coffee files and recursively compiles
    them to *.js files, preserving the original directory structure.

    Jitter also watches for changes and automatically recompiles as
    needed. It even detects new files, unlike the coffee utility.

    If passed a test directory, it will run each test through node on
    each change.

    Usage:
        jitter coffee-path js-path [test-path]
                '''
# Globals
options = {}
baseSource = baseTarget = baseTest = ''
optionParser = null
isWatched = {}
testFiles = []

exports.run = ->

    options = parseOptions()

    return usage() unless baseTarget

    compileScripts options

compileScripts = (options) ->

    dirs = Source: baseSource, Target: baseTarget
    dirs.Test = baseTest if baseTest

    for name, dir of dirs

        q fs.exists, dir, (exists) ->

            unless exists

                die "#{name} directory '#{dir}' does not exist."

            else unless fs.statSync(dir).isDirectory()

                die "#{name} '#{dir}' is a file; Jitter needs a directory."

    q -> rootCompile options

    q runTests

    q ->

        puts 'Watching for changes and new files. Press Ctrl+C to stop.\n'

        setInterval ->

                rootCompile options

        , 500

compile = (source, target, options) ->

    for item in fs.readdirSync source

        sourcePath = "#{source}/#{item}"

        continue if item[0] is '.'
        continue if isWatched[sourcePath]

        try

            if path.extname(sourcePath) is target_ext

                readScript sourcePath, target, options

            else if fs.statSync(sourcePath).isDirectory()

                compile sourcePath, target, options

        catch e

rootCompile = (options) ->

    compile(baseSource, baseTarget, options)
    compile(baseTest, baseTest, options) if baseTest

readScript = (source, target, options) ->

    compileScript(source, target, options)
    watchScript(source, target, options)

watchScript = (source, target, options) ->

    return if isWatched[source]

    isWatched[source]= true

    fs.watchFile source, persistent: true, interval: 250, (curr, prev) ->

        return if curr.mtime.getTime() is prev.mtime.getTime()

        compileScript(source, target, options)
        q runTests

compileScript = (source, target, options) ->

    targetPath = jsPath source, target

    try

        code = fs.readFileSync(source).toString()

        try

            currentJS = fs.readFileSync(targetPath).toString()

        unless options?.map

            options?.map = false

        if options.map

            # We're assuming that the coffee and js reside in the same folder

            slashedTargetPath = targetPath.split('\\').join('/')

            numOfParentDirs = slashedTargetPath.split('/').length - 1

            mapFilename = slashedTargetPath.replace '.js', '.map'

            if mapFilename.lastIndexOf('/') isnt -1

                mapFilename = mapFilename.substr(mapFilename.lastIndexOf('/') + 1)

            jsFilename = mapFilename.replace '.map', '.js'

            pathToRoot = do ->

                _path = []

                _path.push '..' for i in [1..numOfParentDirs]

                _path.join '\\'

            mapPath = slashedTargetPath.substr(0, slashedTargetPath.length - 2) + 'map'

            coffeePath = source.split('\\').join('/').split('/').join('\\')

        js = CoffeeScript.compile code, {

            source
            bare: options?.bare
            sourceMap: options.map
            generatedFile: jsFilename
            sourceRoot: pathToRoot
            sourceFiles: [coffeePath]

        }

        if options.map

            sourceMap = js.v3SourceMap

            js = js.js + '\n/*\n' +

            "//@ sourceMappingURL=#{mapFilename}\n" +

            '*/\n'

        return if js is currentJS

        writeJS js, targetPath

        if sourceMap

            writeSourceMap sourceMap, mapPath

        if currentJS?

            puts 'Recompiled '+ source + '\n'

        else

            puts 'Compiled '+ source + '\n'

    catch err

        # console.log err.location
        #
        msg = do ->

            name = path.basename source

            # + source + ':' + (err.location.first_line + 1) + ': ' + err.message,

            ret = 'Error: '
            ret += source.substr(0, source.length - name.length)
            if err.location?

                ret += color name + ':' + (err.location.first_line + 1), 'bold'

            ret = color ret, 'red'

            ret += '\n\n  ' + err.message

            ret

        puts msg

        if not options?.beep

            `console.log("\007")`

        notify source, err.message

jsPath = (source, target) ->

    base = if target is baseTest then baseTest else baseSource

    filename = path.basename(source, path.extname(source)) + '.js'

    dir =      target + path.dirname(source).substring(base.length)

    path.join dir, filename

writeJS = (js, targetPath) ->

    q exec, "mkdir -p #{path.dirname targetPath}", ->

        fs.writeFileSync targetPath, js

        if baseTest and isSubpath(baseTest, targetPath) and (targetPath not in testFiles)

            testFiles.push targetPath

writeSourceMap = (content, targetPath) ->

    q exec, "mkdir -p #{path.dirname targetPath}", ->

        fs.writeFileSync targetPath, content

notify = (source, errMessage) ->

    basename = source.replace(/^.*[\/\\]/, '')

    if m = errMessage.match /Parse error on line (\d+)/

        message = "Parse error in #{basename}\non line #{m[1]}."

    else

        message = "Error in #{basename}."

    # Use Growl if on Mac.
    if process.platform is 'darwin'
        args = ['growlnotify', '-n', 'CoffeeScript', '-p', '2', '-t', "\"Compilation failed\"", '-m', "\"#{message}\n\'#{errMessage}\'\""]
        exec args.join(' ')
    # Or libnotify if on Linux.
    else
        args = ['notify-send', '-c', 'CoffeeScript', '-t', '5000', "\"Compilation failed\"", "\"#{message}\n\'#{errMessage}\'\""]
        exec args.join(' ')

runTests = ->

    for test in testFiles

        do ->

            output = "  Running " + "#{test}"

            exec "node #{test}", (error, stdout, stderr) ->

                notify test, stderr if stderr

                if stderr

                    if not options?.silent

                        `console.log("\007")`

                    output += color ' ' + 'FAILED ->', 'red'
                    output += '\n' + stdout + stderr + '\n'

                else

                    output += color ' ' + 'PASSED\n', 'green'

                    if stdout

                        output += '\n' + stdout + '\n'

                puts output

                # print stdout
                # print stderr

parseOptions = ->

    optionParser = new optparse.OptionParser [
            ['-b', '--bare', 'compile without the top-level function wrapper'],
            ['-m', '--map', 'compile with source maps'],
            ['-s', '--silent', 'don\'t make beep sounds on errors'],
    ], BANNER

    options =    optionParser.parse process.argv

    [baseSource, baseTarget, baseTest]= (options.arguments[arg] or '' for arg in [2..4])

    if /\/$/.test baseSource then baseSource = baseSource.substr 0, baseSource.length-1

    if /\/$/.test baseTarget then baseTarget = baseTarget.substr 0, baseTarget.length-1

    options

usage = ->

    puts optionParser.help()
    process.exit 0

die = (message) ->

    puts message
    process.exit 1

# http://stackoverflow.com/questions/5888477/
isSubpath = (parent, sub) ->

    parent = fs.realpathSync parent
    sub = fs.realpathSync sub
    sub.indexOf(parent) is 0
