local dial = require 'luanet.dial'
local poll = require 'luanet.poll'
local netaddr = require 'luanet.addr'
local TCPAddr = netaddr.TCPAddr

local M = {}

function M.test_dial()
  local addr = TCPAddr('127.0.0.1', 2345)

  local srvfunc = function ()
    local ln, err = dial.listen('tcp', addr)
    assert_not_nil(ln, err)

    local cn, err = ln:accept()
    assert_not_nil(cn, err)

    cn:close()
    ln:close()
  end

  local clifunc = function ()
    local s, err = dial.dial('tcp', addr)
    assert_not_nil(s, err)

    s:close()
  end

  local srv = poll.run(srvfunc)
  local cli = poll.run(clifunc)
  poll.wait(srv)
  poll.wait(cli)
  assert_true(coroutine.status(srv) == 'dead')
  assert_true(coroutine.status(cli) == 'dead')
end

return M
