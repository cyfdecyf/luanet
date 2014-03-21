local kq = require 'luanet.ffi.kqueue'
local util = require 'luanet.util'
local ffi = require 'ffi'

local M = {}

function M.test_kqueue()
  local q, err = kq.kqueue()
  assert_not_nil(q, util.strerror('create kqueue'))

  local kv = ffi.new('struct kevent[2]')
  local timeout = kq.new_timeout(0.1)
  assert_not_nil(timeout)
  local r, err = kq.kevent(q, nil, 0, nil, 0, timeout)
  assert_true(r == 0, 'kevent with no change and event list should return 0')
  assert_nil(err, util.strerror('kevent with no change and event list'))
end

return M
