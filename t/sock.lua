local socket = require 'luanet.sock_posix'
local sys = require 'luanet.ffi.sys'
local Buffer = sys.Buffer
local poll = require 'luanet.poll'
local log = require 'luanet.log'
local netaddr = require 'luanet.addr'
local TCPAddr = netaddr.TCPAddr

local M = {}

function M.test_socket()
  local addr = TCPAddr('127.0.0.1', 1234)
  local msg = 'hello, world'

  local srvfunc = function ()
    local s, err = socket.socket('tcp',
      sys.AF_INET, sys.SOCK_STREAM, 0, addr, nil)
    assert_not_nil(s, err)
    assert_nil(err)

    local c, err = s:accept()
    assert_not_nil(c, err)
    assert_nil(err)

    local buf = Buffer(10)
    local r = {}
    while true do
      local n, err = c:read(buf, 10)
      if n > 0 then
        r[#r + 1] = sys.buf_to_string(buf, n)
      end
      if err == sys.EOF then break end
      assert_nil(err)
    end
    assert_equal(table.concat(r), msg, 'read message not match')

    c:close()
    s:close()
    log.debug('srv %s finished', coroutine.running())
  end

  local clifunc = function ()
    local s, err = socket.socket('tcp',
      sys.AF_INET, sys.SOCK_STREAM, 0, nil, addr)
    assert_not_nil(s, tostring(err))

    local n, err = s:write(msg)
    assert_equal(n, #msg, '#bytes written not match')
    assert_nil(err)

    s:close()
    log.debug('cli %s finished', coroutine.running())
  end

  local srv = poll.run(srvfunc)
  local cli = poll.run(clifunc)
  poll.wait(srv)
  poll.wait(cli)
  assert_true(coroutine.status(srv) == 'dead')
  assert_true(coroutine.status(cli) == 'dead')
end

return M
