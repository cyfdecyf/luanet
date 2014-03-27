local dial = require 'luanet.dial'
local poll = require 'luanet.poll'

poll.init()

return {
  listen = dial.listen,
  poll = poll.poll,
  wait = poll.wait,
  run = poll.run,
  debugOn = require('luanet.log').debugOn,
}
