local dial = require 'luanet.dial'
local poll = require 'luanet.poll'

local M = {}

function M.test_dial()
  local srv = coroutine.create(function ()
    local ln, err = dial.listen('tcp', { ip = '127.0.0.1', port = 8765 })
    assert_not_nil(ln, err)

    -- local cn, err = ln:accept()
    -- assert_not_nil(cn, err)
  end)

  local cli = coroutine.create(function ()
  end)

  coroutine.resume(srv)
  coroutine.resume(cli)
  poll.wait(srv)
  poll.wait(cli)
  assert_true(coroutine.status(srv) == 'dead')
  assert_true(coroutine.status(cli) == 'dead')
end

return M
