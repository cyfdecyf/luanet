local sock = require 'luanet.sock_posix'
local sys = require 'luanet.ffi.sys'
local util = require 'luanet.util'

local M = {}

local net_tbl = {
  tcp  = { sys.AF_INET,  sys.SOCK_STREAM, 0 },
  tcp6 = { sys.AF_INET6, sys.SOCK_STREAM, 0 },
  udp  = { sys.AF_INET,  sys.SOCK_DGRAM,  0 },
  udp6 = { sys.AF_INET6, sys.SOCK_DGRAM,  0 },
}

-- nettype: 'tcp'
-- laddr: table { ip = '127.0.0.1', port = 8080 }
function M.listen(nettype, laddr)
  local family, sotype, proto = unpack(net_tbl[nettype])
  if family == nil then
    error(string.format('listen: nettype %s not supported', nettype))
  end

  local nfd, err = sock.socket(nettype, family, sotype, proto, laddr, nil)
  if err then
    return nil, 'dial.listen->socket: ' .. err
  end
  return nfd, nil
end

return M
