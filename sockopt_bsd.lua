local sys = require 'luanet.ffi.sys'

local M = {}

function M.set_default_sockopts(sockfd)
  -- TODO allow both IPv6 and IPv4
  return sys.setsockopt(sockfd, sys.SOL_SOCKET, sys.SO_BROADCAST, 1)
end

function M.set_default_listener_sockopts(sockfd)
  return sys.setsockopt(sockfd, sys.SOL_SOCKET, sys.SO_REUSEADDR, 1)
end

return M
