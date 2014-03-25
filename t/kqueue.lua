local kq = require 'luanet.ffi.kqueue'
local pollkq = require 'luanet.poll_kqueue'
local util = require 'luanet.util'
local ffi = require 'ffi'

local M = {}

function M.test_kqueue()
  local q, err = kq.kqueue()
  assert_not_nil(q, util.strerror('create kqueue'))

  local timeout = kq.new_timeout(0.1)
  assert_not_nil(timeout)
  local r, err = kq.kevent(q, nil, 0, nil, 0, timeout)
  assert_true(r == 0, 'kevent with no change and event list should return 0')
  assert_nil(err, util.strerror('kevent with no change and event list'))
end

function M.test_poll_kqueue()
  pollkq.pollinit()
  local pd = { fd = 0 }
  local err = pollkq.pollopen(pd)
  assert_nil(err)
end

return M
