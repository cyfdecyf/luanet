local kq = require 'luanet.ffi.kqueue'
local pollkq = require 'luanet.poll_kqueue'

local M = {}

function M.test_kqueue()
  local q, err = kq.kqueue()
  assert_not_nil(q, 'create kqueue: ' .. tostring(err))

  local timeout = kq.new_timeout(100000)
  assert_not_nil(timeout)
  local r, err = kq.kevent(q, nil, 0, nil, 0, timeout)
  assert_true(r == 0, 'kevent with no change and event list should return 0')
  assert_nil(err, 'kevent with no change and event list' .. tostring(err))
end

return M
