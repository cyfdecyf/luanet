local lunatest = require 'lunatest'
local log = require 'luanet.log'

log.debug_off()

local net = require 'luanet' -- must require this to do initialization
local sys = require 'luanet.ffi.sys'

lunatest.suite('luanet.t.sys')
if sys.os == 'OSX' then
  lunatest.suite('luanet.t.kqueue')
end

lunatest.suite('luanet.t.addr')
lunatest.suite('luanet.t.sock')
lunatest.suite('luanet.t.dial')

lunatest.run()
