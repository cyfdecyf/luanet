require 'lunatest'

local log = require 'luanet.log'

function test_debug()
  log.debugOn = false
  log.debug('hello')
end

lunatest.run()
