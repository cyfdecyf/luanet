local dial = require 'luanet.dial'
local sys = require 'luanet.ffi.sys'
local Buffer = sys.Buffer
local poll = require 'luanet.poll'
local netaddr = require 'luanet.addr'
local TCPAddr = netaddr.TCPAddr

local M = {}

function M.test_dial()
  local addr = TCPAddr('127.0.0.1', 2345)
  local msg = 'hello, world'

  local srvfunc = function ()
    local ln, err = dial.listen('tcp', addr)
    assert_not_nil(ln, err)

    local cn, err = ln:accept()
    assert_not_nil(cn, err)

    local n, err = cn:write(msg)
    assert_equal(n, #msg, '#bytes written not match')
    assert_nil(err)

    cn:close()
    ln:close()
  end

  local clifunc = function ()
    local s, err = dial.dial('tcp', addr)
    assert_not_nil(s, err)

    local buf = Buffer(10)
    local r = {}
    while true do
      local n, err = s:read(buf, 10)
      if n > 0 then
        r[#r + 1] = sys.buf_to_string(buf, n)
      end
      if err == sys.EOF then break end
      assert_nil(err)
    end
    assert_equal(table.concat(r), msg, 'read message not match')

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
