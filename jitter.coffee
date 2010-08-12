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
fs=            require 'fs'
path=          require 'path'
optparse=      require './optparse'
CoffeeScript=  require './coffee-script'
{spawn, exec}= require('child_process')

# Banner shown if jitter is run without arguments
BANNER= '''
  Jitter takes a directory of *.coffee files and recursively compiles
  them to *.js files, preserving the original directory structure.

  Jitter also watches for changes and automatically recompiles as
  needed. It even detects new files, unlike the coffee utility.

  Usage:
    jitter coffee-path js-path
        '''
# Globals
options= {}
baseSource= ''
baseTarget= ''
optionParser= null
isWatched= {}

exports.run= ->
  parseOptions()
  return usage() unless baseTarget
  compileScripts()

compileScripts= ->
  path.exists baseSource, (exists) ->
    unless exists
      die "Source directory '#{baseSource}' does not exist."
    else unless fs.statSync(baseSource).isDirectory()
      die "Source '#{baseSource}' is a file; Jitter needs a directory."
  path.exists baseTarget, (exists) ->
    unless exists
      die "Target directory '#{baseTarget}' does not exist."
    else unless fs.statSync(baseTarget).isDirectory()
      die "Target '#{baseTarget}' is a file; Jitter needs a directory."

  compile= (source, target) ->
    changed= false
    for item in fs.readdirSync source
      sourcePath= "#{source}/#{item}"
      continue if isWatched[sourcePath]
      if path.extname(sourcePath) is '.coffee'
        readScript sourcePath
      else if fs.statSync(sourcePath).isDirectory()
        compile sourcePath

  rootCompile= ->
    compile(baseSource, baseTarget)

  rootCompile()
  puts 'Watching for changes and new files. Press Ctrl+C to stop.'
  setInterval rootCompile, 500

readScript= (source) ->
  fs.readFile source, (err, code) -> compileScript(source, code.toString())
  puts 'Compiled '+ source
  watchScript(source)

watchScript= (source) ->
  isWatched[source] = true
  fs.watchFile source, {persistent: true, interval: 250}, (curr, prev) ->
    return if curr.mtime.getTime() is prev.mtime.getTime()
    fs.readFile source, (err, code) -> compileScript(source, code.toString())
    puts 'Recompiled '+ source

compileScript= (source, code) ->
  try
    js= CoffeeScript.compile code, {source}
    writeJS source, js
  catch err
    puts err.message
    notifyGrowl source, err

writeJS= (source, js) ->
  filename= path.basename(source, path.extname(source)) + '.js'
  dir=      baseTarget + path.dirname(source).substring(baseSource.length)
  jsPath=  path.join dir, filename
  exec "mkdir -p #{dir}", (error, stdout, stderr) -> fs.writeFile(jsPath, js)

notifyGrowl= (source, err) ->
  basename= source.replace(/^.*[\/\\]/, '')
  if m= err.message.match /Parse error on line (\d+)/
    message= "Parse error in #{basename}\non line #{m[1]}."
  else
    message= "Error when compiling #{basename}."
  args= ['growlnotify', '-n', 'CoffeeScript', '-p', '2', '-t', "\"Compilation failed\"", '-m', "\"#{message}\""]
  exec args.join(' ')

parseOptions= ->
  optionParser= new optparse.OptionParser [], BANNER
  options=    optionParser.parse process.argv
  baseSource=    options.arguments[2]
  if baseSource[-1] is '/' then baseSource = baseSource[0...-1]
  baseTarget=    options.arguments[3]
  if baseTarget[-1] is '/' then baseTarget = baseTarget[0...-1]

usage= ->
  puts optionParser.help()
  process.exit 0

die= (message) ->
  puts message
  process.exit 1