#!/usr/bin/env node

# Jitter, a CoffeeScript compilation utility
# 
# The latest version and documentation, can be found at:
# http://github.com/TrevorBurnham/Jitter
# 
# Copyright (c) 2010 Trevor Burnham
# http://iterative.ly
# 
# Based on command.coffee by Jeremy Ashkenas.
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

fs:           require 'fs'
path:         require 'path'
optparse:     require './optparse'
CoffeeScript: require './coffee-script'
{spawn: spawn, exec: exec}: require('child_process')

BANNER: '''
  Jitter takes a directory of *.coffee files and recursively compiles
  them to *.js files, preserving the original directory structure.

  Usage:
    jitter [-flags] coffee-path js-path
        '''

SWITCHES: [
  ['-w', '--watch',         'automatically recompile as changes are made']
  ['-v', '--verbose',       'print superfluous output']
  ['-h', '--help',          'display this help message']
]

options: {}
baseSource: ''
baseTarget: ''
option_parser: null
isWatched: {}

exports.run: ->
  parse_options()
  return usage()    if options.help
  return usage()    unless baseTarget
  compile_scripts()

compile_scripts: ->
  path.exists baseSource, (exists) ->
    if ! exists
      puts "Source directory '$baseSource' does not exist."; process.exit(1)
    else if ! fs.statSync(baseSource).isDirectory()
      puts "Source '$baseSource' is a file; Jitter needs a directory."; process.exit(1)
  path.exists baseTarget, (exists) ->
    if ! exists
      puts "Target directory '$baseTarget' does not exist."; process.exit(1)
    else if ! fs.statSync(baseTarget).isDirectory()
      puts "Target '$baseTarget' is a file; Jitter needs a directory."; process.exit(1)

  compile: (source, target) ->
    for i in fs.readdirSync(source)
      sourcePath: source +'/'+ i
      continue    if isWatched[sourcePath]
      if path.extname(sourcePath) == '.coffee'
        read_script (sourcePath)
      else if fs.statSync(sourcePath).isDirectory()
        compile sourcePath
  
  root_compile: ->
    compile(baseSource, baseTarget)
  
  root_compile()
  if options.watch
    setInterval root_compile, 500

read_script: (source) ->
  puts 'Compiling '+ source   if options.verbose
  fs.readFile source, (err, code) -> compile_script(source, code)
  watch_script(source)        if options.watch

watch_script: (source) ->
  isWatched[source] = true
  fs.watchFile source, {persistent: true, interval: 500}, (curr, prev) ->
    return if curr.mtime.getTime() is prev.mtime.getTime()
    puts 'Recompiling '+ source   if options.verbose
    fs.readFile source, (err, code) -> compile_script(source, code)

compile_script: (source, code) ->
  o: options
  code_opts: compile_options source
  try
    js: CoffeeScript.compile code, code_opts
    write_js source, js
  catch err
    if o.watch            then puts err.message else throw err

write_js: (source, js) ->
  filename: path.basename(source, path.extname(source)) + '.js'
  dir:      baseTarget + path.dirname(source).substring(baseSource.length)
  js_path:  path.join dir, filename
  exec "mkdir -p $dir", (error, stdout, stderr) -> fs.writeFile(js_path, js)

parse_options: ->
  option_parser: new optparse.OptionParser SWITCHES, BANNER
  o: options:    option_parser.parse(process.argv)
  options.run:   not (o.compile or o.print or o.lint)
  options.print: !!  (o.print or (o.eval or o.stdio and o.compile))
  baseSource:    options.arguments[2]
  baseTarget:    options.arguments[3]

compile_options: (source) ->
  o: {source: source}
  o['no_wrap']: options['no-wrap']
  o

usage: ->
  puts option_parser.help()
  process.exit 0