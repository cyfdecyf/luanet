local socket = require 'luanet.sock_posix'
local sys = require 'luanet.ffi.sys'
local poll = require 'luanet.poll'

local M = {}

function test_socket()
  local t = coroutine.create(function ()
    local s, err = socket.socket('tcp',
      sys.AF_INET, sys.SOCK_STREAM, 0,
      { ip = '127.0.0.1', port = 8764 }, nil)
    assert_not_nil(s, err)

    err = s:init()
    assert_nil(err)

    s:close()
  end)
  coroutine.resume(t)

  poll.wait(t)
  assert_true(coroutine.status(t) == 'dead')
end

return M
