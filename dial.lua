local sock = require 'luanet.sock_posix'
local sys = require 'luanet.ffi.sys'
local util = require 'luanet.util'

local M = {}

-- nettype: 'tcp'
-- laddr: table { ip = '127.0.0.1', port = 8080 }
function M.listen(nettype, laddr)
  local nfd, err = sock.socket(nettype,
    sys.AF_INET, sys.SOCK_STREAM, 0, laddr, nil)
  if err then
    return nil, util.strerror('dial.listen->socket')
  end
  return nfd, nil
end

return M
