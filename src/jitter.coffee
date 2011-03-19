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
CoffeeScript=  require 'coffee-script'
{exec}=        require 'child_process'
{puts, print}= require 'sys'
{q}=           require 'sink'

# Banner shown if jitter is run without arguments
BANNER= '''
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
options= {}
baseSource= baseTarget= baseTest= ''
optionParser= null
isWatched= {}
testFiles= []

exports.run= ->
  options = parseOptions()
  return usage() unless baseTarget
  compileScripts(options)

compileScripts= (options) ->
  dirs= Source: baseSource, Target: baseTarget
  dirs.Test= baseTest if baseTest
  for name, dir of dirs 
    q path.exists, dir, (exists) ->
      unless exists
        die "#{name} directory '#{dir}' does not exist."
      else unless fs.statSync(dir).isDirectory()
        die "#{name} '#{dir}' is a file; Jitter needs a directory."
  q -> rootCompile options
  q runTests
  q ->  
    puts 'Watching for changes and new files. Press Ctrl+C to stop.'
    setInterval ->
        rootCompile options
    , 500

compile= (source, target, options) ->
  for item in fs.readdirSync source
    sourcePath= "#{source}/#{item}"
    continue if isWatched[sourcePath]
    if path.extname(sourcePath) is '.coffee'
      readScript sourcePath, target, options
    else if fs.statSync(sourcePath).isDirectory()
      compile sourcePath, target, options
    
rootCompile= (options) ->
  compile(baseSource, baseTarget, options)
  compile(baseTest, baseTest, options) if baseTest

readScript= (source, target, options) ->
  compileScript(source, target, options)
  puts 'Compiled '+ source
  watchScript(source, target, options)

watchScript= (source, target, options) ->
  isWatched[source]= true
  fs.watchFile source, persistent: true, interval: 250, (curr, prev) ->
    return if curr.mtime.getTime() is prev.mtime.getTime()
    compileScript(source, target, options)
    puts 'Recompiled '+ source
    q runTests

compileScript= (source, target, options) ->
  try
    code= fs.readFileSync(source).toString()
    js= CoffeeScript.compile code, {source, bare: options?.bare}
    writeJS source, js, target
  catch err
    puts err.message
    notifyGrowl source, err.message

writeJS= (source, js, target) ->
  base= if target is baseTest then baseTest else baseSource
  filename= path.basename(source, path.extname(source)) + '.js'
  dir=      target + path.dirname(source).substring(base.length)
  jsPath=  path.join dir, filename
  q exec, "mkdir -p #{dir}", ->
    fs.writeFileSync jsPath, js
    testFiles.push jsPath if target is baseTest and jsPath not in testFiles 
      
notifyGrowl= (source, errMessage) ->
  basename= source.replace(/^.*[\/\\]/, '')
  if m= errMessage.match /Parse error on line (\d+)/
    message= "Parse error in #{basename}\non line #{m[1]}."
  else
    message= "Error in #{basename}."
  args= ['growlnotify', '-n', 'CoffeeScript', '-p', '2', '-t', "\"Compilation failed\"", '-m', "\"#{message}\""]
  exec args.join(' ')

runTests= ->
  for test in testFiles
    puts "running #{test}"
    exec "node #{test}", (error, stdout, stderr) ->
      print stdout
      print stderr
      notifyGrowl test, stderr if stderr

parseOptions= ->
  optionParser= new optparse.OptionParser [
      ['-b', '--bare', 'compile without the top-level function wrapper']
  ], BANNER
  options=    optionParser.parse process.argv
  [baseSource, baseTarget, baseTest]= (options.arguments[arg] or '' for arg in [2..4])
  if /\/$/.test baseSource then baseSource= baseSource.substr 0, baseSource.length-1
  if /\/$/.test baseTarget then baseTarget= baseTarget.substr 0, baseTarget.length-1
  options

usage= ->
  puts optionParser.help()
  process.exit 0

die= (message) ->
  puts message
  process.exit 1
