#!/usr/bin/env luajit

local lunatest = require 'lunatest'

require 'pl.strict'

local net = require 'luanet' -- do initialization
local sys = require 'luanet.ffi.sys'

require('luanet.log').debug_off()

lunatest.suite('luanet.t.sys')
if sys.os == 'OSX' then
  lunatest.suite('luanet.t.kqueue')
end

lunatest.suite('luanet.t.addr')
lunatest.suite('luanet.t.sock')
lunatest.suite('luanet.t.dial')

lunatest.run()
