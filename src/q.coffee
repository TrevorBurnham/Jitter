{debug} = require 'sys'
__callbacks = []
#Call functions in sequence.
#Assumes you'll pass a plain no arg function, or a function and a callback.
(window? or exports).q = (func, args..., cb) ->
  next = -> __callbacks[0]?()
  process.nextTick next if __callbacks.length == 0
  __callbacks.push ->
    [cb, func] = [func, process.nextTick] unless cb
    func args..., (results...) ->
      [callbacks, __callbacks] = [__callbacks,[null]]
      cb results...
      callbacks.splice 0, 1, __callbacks[1..]...
      __callbacks = callbacks
      next()
