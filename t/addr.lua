local netaddr = require 'luanet.addr'
local TCPAddr = netaddr.TCPAddr

local M = {}

function M.test_TCPAddr()
  local status = pcall(TCPAddr.new, TCPAddr)
  assert_false(status, 'TCPAddr() should always have ip and port')

  status = pcall(TCPAddr, TCPAddr, {1234, 1234})
  assert_false(status, 'TCPAddr() should check type of ip for table')

  status = pcall(TCPAddr, TCPAddr, 1234, 1234)
  assert_false(status, 'TCPAddr:new should check type of ip')

  status = pcall(TCPAddr, TCPAddr, { ip = 1234, port = 1234 })
  assert_false(status, 'TCPAddr:new should check type of ip for table')

  status = pcall(TCPAddr, TCPAddr, '127.0.0.1', '1234')
  assert_false(status, 'TCPAddr:new should check type of port')

  local ad = TCPAddr('127.0.0.1', 1234)
  assert_equal('TCPAddr(127.0.0.1:1234)', tostring(ad))

  ad = TCPAddr{ ip = '127.0.0.1', port = 1234 }
  assert_equal('TCPAddr(127.0.0.1:1234)', tostring(ad))
end

return M
