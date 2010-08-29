(function() {
  var BANNER, CoffeeScript, _a, baseSource, baseTarget, compileScript, compileScripts, die, exec, fs, isWatched, notifyGrowl, optionParser, options, optparse, parseOptions, path, readScript, spawn, usage, watchScript, writeJS;
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
  fs = require('fs');
  path = require('path');
  optparse = require('./optparse');
  CoffeeScript = require('coffee-script');
  _a = require('child_process');
  spawn = _a.spawn;
  exec = _a.exec;
  BANNER = 'Jitter takes a directory of *.coffee files and recursively compiles\nthem to *.js files, preserving the original directory structure.\n\nJitter also watches for changes and automatically recompiles as\nneeded. It even detects new files, unlike the coffee utility.\n\nUsage:\n  jitter coffee-path js-path';
  options = {};
  baseSource = '';
  baseTarget = '';
  optionParser = null;
  isWatched = {};
  exports.run = function() {
    parseOptions();
    if (!(baseTarget)) {
      return usage();
    }
    return compileScripts();
  };
  compileScripts = function() {
    var compile, rootCompile;
    path.exists(baseSource, function(exists) {
      return !(exists) ? die("Source directory '" + (baseSource) + "' does not exist.") : (!(fs.statSync(baseSource).isDirectory()) ? die("Source '" + (baseSource) + "' is a file; Jitter needs a directory.") : null);
    });
    path.exists(baseTarget, function(exists) {
      return !(exists) ? die("Target directory '" + (baseTarget) + "' does not exist.") : (!(fs.statSync(baseTarget).isDirectory()) ? die("Target '" + (baseTarget) + "' is a file; Jitter needs a directory.") : null);
    });
    compile = function(source, target) {
      var _b, _c, _d, _e, changed, item, sourcePath;
      changed = false;
      _b = []; _d = fs.readdirSync(source);
      for (_c = 0, _e = _d.length; _c < _e; _c++) {
        item = _d[_c];
        sourcePath = ("" + (source) + "/" + (item));
        if (isWatched[sourcePath]) {
          continue;
        }
        if (path.extname(sourcePath) === '.coffee') {
          readScript(sourcePath);
        } else if (fs.statSync(sourcePath).isDirectory()) {
          compile(sourcePath);
        }
      }
      return _b;
    };
    rootCompile = function() {
      return compile(baseSource, baseTarget);
    };
    rootCompile();
    puts('Watching for changes and new files. Press Ctrl+C to stop.');
    return setInterval(rootCompile, 500);
  };
  readScript = function(source) {
    fs.readFile(source, function(err, code) {
      return compileScript(source, code.toString());
    });
    puts('Compiled ' + source);
    return watchScript(source);
  };
  watchScript = function(source) {
    isWatched[source] = true;
    return fs.watchFile(source, {
      persistent: true,
      interval: 250
    }, function(curr, prev) {
      if (curr.mtime.getTime() === prev.mtime.getTime()) {
        return null;
      }
      fs.readFile(source, function(err, code) {
        return compileScript(source, code.toString());
      });
      return puts('Recompiled ' + source);
    });
  };
  compileScript = function(source, code) {
    var js;
    try {
      js = CoffeeScript.compile(code, {
        source: source
      });
      return writeJS(source, js);
    } catch (err) {
      puts(err.message);
      return notifyGrowl(source, err);
    }
  };
  writeJS = function(source, js) {
    var dir, filename, jsPath;
    filename = path.basename(source, path.extname(source)) + '.js';
    dir = baseTarget + path.dirname(source).substring(baseSource.length);
    jsPath = path.join(dir, filename);
    return exec("mkdir -p " + (dir), function(error, stdout, stderr) {
      return fs.writeFile(jsPath, js);
    });
  };
  notifyGrowl = function(source, err) {
    var args, basename, m, message;
    basename = source.replace(/^.*[\/\\]/, '');
    if (m = err.message.match(/Parse error on line (\d+)/)) {
      message = ("Parse error in " + (basename) + "\non line " + (m[1]) + ".");
    } else {
      message = ("Error when compiling " + (basename) + ".");
    }
    args = ['growlnotify', '-n', 'CoffeeScript', '-p', '2', '-t', "\"Compilation failed\"", '-m', ("\"" + (message) + "\"")];
    return exec(args.join(' '));
  };
  parseOptions = function() {
    optionParser = new optparse.OptionParser([], BANNER);
    options = optionParser.parse(process.argv);
    if (options.arguments[2]) {
      baseSource = options.arguments[2];
    }
    if (options.arguments[3]) {
      baseTarget = options.arguments[3];
    }
    if (baseSource[-1] === '/') {
      baseSource = baseSource.slice(0, -1);
    }
    return baseTarget[-1] === '/' ? (baseTarget = baseTarget.slice(0, -1)) : null;
  };
  usage = function() {
    puts(optionParser.help());
    return process.exit(0);
  };
  die = function(message) {
    puts(message);
    return process.exit(1);
  };
})();
