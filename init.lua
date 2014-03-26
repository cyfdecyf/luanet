local dial = require 'luanet.dial'
local poll = require 'luanet.poll'

poll.init()

return {
  listen = dial.listen
}
