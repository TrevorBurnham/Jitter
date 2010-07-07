# Jitter

A simple compilation utility for [CoffeeScript](http://coffeescript.org).

Jitter watches for new files and changes to files in the CoffeeScript source directory
you specify, and compiles new JavaScript files as needed. No flags, no worries, just the
sweet CoffeeScript compilation you need when you need it.

## Installing

First you'll need to install CoffeeScript, if you don't have it already (if you have it,
`coffee -v` will display the version  number). If you have Homebrew, you can just run

  `brew install coffee-script`

Otherwise, instructions can be found at http://github.com/jashkenas/coffee-script.

Once you have CoffeeScript on your path, just download Jitter and run

  `./install`

You've now got Jitter!

## To use:

Let's say you have a bunch of `*.coffee` files in the `coffee` directory, and want to
compile them to the `js` directory. Then run:

    jitter coffee js

Jitter runs in the background until you terminate it (Ctrl+C), watching for new changes.

Or let's say you want to take `*.coffee` files from the `src` directory and compile them
to the current directory. Then run

    jitter src .

For more info, see http://iterative.ly/2010/05/03/introducing-jitter/

## Growl notifications

Jitter will display a growl notification whenever compilation fails, provided that you
have [growlnotify](http://growl.info/extras.php) installed and on your PATH. This allows
you to run Jitter silently in the background, not worrying about it until you get a
syntax error.

## Copyright

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