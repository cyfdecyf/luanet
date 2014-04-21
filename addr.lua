local M = {}

local sys = require 'luanet.ffi.sys'
local class = require 'pl.class'

M.TCPAddr = class.TCPAddr()

function TCPAddr:_init(ip, port)
  if type(ip) == 'table' and port == nil then
    port = ip.port
    ip = ip.ip
  end
  if type(ip) ~= 'string' or type(port) ~= 'number' then
    error('invalid argument to TCPAddr')
  end
  self.ip = ip
  self.port = port
end

function TCPAddr:__tostring()
  return string.format('TCPAddr(%s:%d)', self.ip, self.port)
end

-- convert to struct sockaddr that can be used with syscall
function TCPAddr:to_sockaddr()
  return sys.ip_to_sockaddr(sys.AF_INET, self)
end

return M
