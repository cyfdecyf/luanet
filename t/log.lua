require 'lunatest'

local log = require 'luanet.log'

function test_debug()
  log.debug_off()
  log.debug('hello')
end

lunatest.run()
