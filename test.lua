local lunatest = require 'lunatest'
local sys = require 'luanet.ffi.sys'

lunatest.suite('luanet.t.sys')
if sys.os == 'OSX' then
  lunatest.suite('luanet.t.kqueue')
end

lunatest.suite('luanet.t.sock')
lunatest.suite('luanet.t.dial')

lunatest.run()
