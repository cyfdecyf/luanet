local dial = require 'luanet.dial'
local poll = require 'luanet.poll'
local sys = require 'luanet.ffi.sys'
local log = require 'luanet.log'

poll.init()

return {
  listen = dial.listen,
  poll = poll.poll,
  wait = poll.wait,
  run = poll.run,
  sys = sys,
  debug_on = log.debug_on,
  debug_off = log.debug_off,
}
