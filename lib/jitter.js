(function() {

  /*
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
  */

  var BANNER, CoffeeScript, baseSource, baseTarget, baseTest, compile, compileScript, compileScripts, die, exec, fs, isSubpath, isWatched, jsPath, notify, optionParser, options, optparse, parseOptions, path, print, puts, q, readScript, rootCompile, runTests, target_ext, targetlib, testFiles, usage, watchScript, writeJS, _ref;
  var __hasProp = Object.prototype.hasOwnProperty, __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (__hasProp.call(this, i) && this[i] === item) return i; } return -1; };

  fs = require('fs');

  path = require('path');

  optparse = require('./optparse');

  if (path.basename(process.argv[1]) === 'witter') {
    targetlib = 'coco';
    target_ext = '.coco';
  } else {
    targetlib = 'coffee-script';
    target_ext = '.coffee';
  }

  CoffeeScript = require(targetlib);

  exec = require('child_process').exec;

  _ref = (function() {
    try {
      return require('util');
    } catch (e) {
      return require('sys');
    }
  })(), puts = _ref.puts, print = _ref.print;

  q = require('sink').q;

  BANNER = 'Jitter takes a directory of *.coffee files and recursively compiles\nthem to *.js files, preserving the original directory structure.\n\nJitter also watches for changes and automatically recompiles as\nneeded. It even detects new files, unlike the coffee utility.\n\nIf passed a test directory, it will run each test through node on\neach change.\n\nUsage:\n  jitter coffee-path js-path [test-path]';

  options = {};

  baseSource = baseTarget = baseTest = '';

  optionParser = null;

  isWatched = {};

  testFiles = [];

  exports.run = function() {
    options = parseOptions();
    if (!baseTarget) return usage();
    return compileScripts(options);
  };

  compileScripts = function(options) {
    var dir, dirs, name;
    dirs = {
      Source: baseSource,
      Target: baseTarget
    };
    if (baseTest) dirs.Test = baseTest;
    for (name in dirs) {
      dir = dirs[name];
      q(path.exists, dir, function(exists) {
        if (!exists) {
          return die("" + name + " directory '" + dir + "' does not exist.");
        } else if (!fs.statSync(dir).isDirectory()) {
          return die("" + name + " '" + dir + "' is a file; Jitter needs a directory.");
        }
      });
    }
    q(function() {
      return rootCompile(options);
    });
    q(runTests);
    return q(function() {
      puts('Watching for changes and new files. Press Ctrl+C to stop.');
      return setInterval(function() {
        return rootCompile(options);
      }, 500);
    });
  };

  compile = function(source, target, options) {
    var item, sourcePath, _i, _len, _ref2, _results;
    _ref2 = fs.readdirSync(source);
    _results = [];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      item = _ref2[_i];
      sourcePath = "" + source + "/" + item;
      if (item[0] === '.') continue;
      if (isWatched[sourcePath]) continue;
      try {
        if (path.extname(sourcePath) === target_ext) {
          _results.push(readScript(sourcePath, target, options));
        } else if (fs.statSync(sourcePath).isDirectory()) {
          _results.push(compile(sourcePath, target, options));
        } else {
          _results.push(void 0);
        }
      } catch (e) {

      }
    }
    return _results;
  };

  rootCompile = function(options) {
    compile(baseSource, baseTarget, options);
    if (baseTest) return compile(baseTest, baseTest, options);
  };

  readScript = function(source, target, options) {
    compileScript(source, target, options);
    return watchScript(source, target, options);
  };

  watchScript = function(source, target, options) {
    if (isWatched[source]) return;
    isWatched[source] = true;
    return fs.watchFile(source, {
      persistent: true,
      interval: 250
    }, function(curr, prev) {
      if (curr.mtime.getTime() === prev.mtime.getTime()) return;
      compileScript(source, target, options);
      return q(runTests);
    });
  };

  compileScript = function(source, target, options) {
    var code, currentJS, js, targetPath;
    targetPath = jsPath(source, target);
    try {
      code = fs.readFileSync(source).toString();
      try {
        currentJS = fs.readFileSync(targetPath).toString();
      } catch (_error) {}
      js = CoffeeScript.compile(code, {
        source: source,
        bare: options != null ? options.bare : void 0
      });
      if (js === currentJS) return;
      writeJS(js, targetPath);
      if (currentJS != null) {
        return puts('Recompiled ' + source);
      } else {
        return puts('Compiled ' + source);
      }
    } catch (err) {
      puts(err.message);
      return notify(source, err.message);
    }
  };

  jsPath = function(source, target) {
    var base, dir, filename;
    base = target === baseTest ? baseTest : baseSource;
    filename = path.basename(source, path.extname(source)) + '.js';
    dir = target + path.dirname(source).substring(base.length);
    return path.join(dir, filename);
  };

  writeJS = function(js, targetPath) {
    return q(exec, "mkdir -p " + (path.dirname(targetPath)), function() {
      fs.writeFileSync(targetPath, js);
      if (baseTest && isSubpath(baseTest, targetPath) && (__indexOf.call(testFiles, targetPath) < 0)) {
        return testFiles.push(targetPath);
      }
    });
  };

  notify = function(source, errMessage) {
    var args, basename, m, message;
    basename = source.replace(/^.*[\/\\]/, '');
    if (m = errMessage.match(/Parse error on line (\d+)/)) {
      message = "Parse error in " + basename + "\non line " + m[1] + ".";
    } else {
      message = "Error in " + basename + ".";
    }
    if (process.platform === 'darwin') {
      args = ['growlnotify', '-n', 'CoffeeScript', '-p', '2', '-t', "\"Compilation failed\"", '-m', "\"" + message + "\""];
      return exec(args.join(' '));
    } else {
      args = ['notify-send', '-c', 'CoffeeScript', '-t', '2', "\"Compilation failed\"", "\"" + message + "\""];
      return exec(args.join(' '));
    }
  };

  runTests = function() {
    var test, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = testFiles.length; _i < _len; _i++) {
      test = testFiles[_i];
      puts("Running " + test);
      _results.push(exec("node " + test, function(error, stdout, stderr) {
        print(stdout);
        print(stderr);
        if (stderr) return notify(test, stderr);
      }));
    }
    return _results;
  };

  parseOptions = function() {
    var arg, _ref2;
    optionParser = new optparse.OptionParser([['-b', '--bare', 'compile without the top-level function wrapper']], BANNER);
    options = optionParser.parse(process.argv);
    _ref2 = (function() {
      var _results;
      _results = [];
      for (arg = 2; arg <= 4; arg++) {
        _results.push(options.arguments[arg] || '');
      }
      return _results;
    })(), baseSource = _ref2[0], baseTarget = _ref2[1], baseTest = _ref2[2];
    if (/\/$/.test(baseSource)) {
      baseSource = baseSource.substr(0, baseSource.length - 1);
    }
    if (/\/$/.test(baseTarget)) {
      baseTarget = baseTarget.substr(0, baseTarget.length - 1);
    }
    return options;
  };

  usage = function() {
    puts(optionParser.help());
    return process.exit(0);
  };

  die = function(message) {
    puts(message);
    return process.exit(1);
  };

  isSubpath = function(parent, sub) {
    parent = fs.realpathSync(parent);
    sub = fs.realpathSync(sub);
    return sub.indexOf(parent) === 0;
  };

}).call(this);
