local M = {}

local sys = require 'luanet.ffi.sys'

local TCPAddr = {}
TCPAddr.__index = TCPAddr
M.TCPAddr = TCPAddr

-- Either give ip, port or use a table like { ip = '127.0.0.1', port = 1234 }
function TCPAddr:new(ip, port)
  if type(ip) == 'table' and port == nil then
    port = ip.port
    ip = ip.ip
  end
  if type(ip) ~= 'string' or type(port) ~= 'number' then
    error('invalid argument to TCPAddr')
  end
  return setmetatable({ ip = ip, port = port }, self)
end

function TCPAddr:__tostring()
  return string.format('TCPAddr(%s:%d)', self.ip, self.port)
end

-- convert to struct sockaddr that can be used with syscall
function TCPAddr:to_sockaddr()
  return sys.ip_to_sockaddr(sys.AF_INET, self)
end

return M
