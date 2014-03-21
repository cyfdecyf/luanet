local socket = require 'luanet.sock_posix'
local sys = require 'luanet.ffi.sys'

local M = {}

function M.test_socket()
  local s, err = socket.socket('tcp',
    sys.AF_INET, sys.SOCK_STREAM, 0,
    { ip = '127.0.0.1', port = 8764 }, nil)
  assert_not_nil(s, err)
  s:close()
end

return M
