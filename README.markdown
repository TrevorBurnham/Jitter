# Jitter

Simple continuous compilation for [CoffeeScript](http://coffeescript.org), from the author
of *[CoffeeScript: Accelerated JavaScript Development](http://pragprog.com/titles/tbcoffee/coffeescript)*.

Jitter watches for new files and changes to files in the CoffeeScript source directory
you specify, and compiles new JavaScript files as needed. No flags, no worries, just the
sweet CoffeeScript compilation you need when you need it.

***Bonus!*** Jitter gives you Growl notifications when compilation fails! See below for
details.

***Extra bonus!*** Jitter lets you automatically compile and run a second set of code after
each successful compilation. That means that console-based tests are a breeze.

***Extra, extra bonus!*** Jitter only replaces JS files when necessary (that is, when your
CoffeeScript and JavaScript are out of sync). So no more meaningless timestamp changes!


## Installing

You'll need to install [Node.js](http://nodejs.org) and [npm](http://npmjs.org/), the
Node Package Manager. If you don't already have CoffeeScript installed (check with
`require('coffee-script')` from Node), run

    npm install -g coffee-script

(The `-g` flag tells npm that you want to do a *global* install, rather than just making
the library available to a particular project.) And adding Jitter is just as easy:

    npm install -g jitter

Make sure that the `bin` directory that `coffee` and `jitter` are installed to is on
your PATH.

### From source

To build and install Jitter from source:

    git clone git://github.com/TrevorBurnham/Jitter.git
    cd Jitter
    npm install -g

## To use:

### From the command line

Let's say you have a bunch of `*.coffee` files in the `coffee` directory, and want to
compile them to the `js` directory. Then run:

    jitter coffee js

Jitter runs in the background until you terminate it (Ctrl+C), watching for new changes.

Or let's say you want to take `*.coffee` files from the `src` directory and compile them
to the current directory. Then run

    jitter src .

To automatically run your tests after each change, specify a test directory:

    jitter coffee js test

To generate source maps alongside the JavaScript files (Coffee will add the directives automatically):

	jitter coffee js -m

To compile the JavaScript without the top-level function safety wrapper:

	jitter coffee js -b

As an example, this would watch the coffee folder, compile into the js folder, generate sourcemaps, and run the tests:

	jitter coffee js test -m

If you don't want to hear a beep sound on errors, pass '-s' as an option:

    jitter coffee js -s

Tests will be compiled to js in place, then executed with node. Tests are automatically
re-executed when changed.

### From your own module or script

Jitter may be required from within your module:

```js
var jitter = require('jitter');
```

And started, with output (currently) being directed straight to your stdout:

```js
jitter('src', 'lib');
```

Or if you have a suite of tests you'd like to run as well (as above):

```js
jitter('src', 'lib', 'test');
```

## Growl notifications

Jitter will display a growl notification whenever compilation fails, provided that you
have [growlnotify](http://growl.info/extras.php) installed and on your PATH. This allows
you to run Jitter silently in the background, not worrying about it until you get a
syntax error.

Growl notifications are also shown if an error is encountered while running a test,
including uncaught `AssertionError`s.

## Credits

Originally written by [Trevor Burnham](http://github.com/TrevorBurnham). Updated to
CoffeeScript 0.9 by [cj](http://github.com/cj). Growl notification code pulled from work
by [Andrey Tarantsov](http://www.tarantsov.com/). Post-compile hook code added by Scott
Wadden ([hiddenbek](http://github.com/hiddenbek)). Various patches by Nao izuka ([iizukanao](https://github.com/iizukanao)). Source maps support by Aria Minaei ([AriaMinaei](https://github.com/AriaMinaei)).

## Copyright

Copyright (c) 2011 Trevor Burnham
http://trevorburnham.com

Based on command.coffee by Jeremy Ashkenas
http://jashkenas.github.com/coffee-script/documentation/docs/command.html

MIT licensed:

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
