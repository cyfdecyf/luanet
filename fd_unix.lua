local M = {}

local NetFD = {}
local sys = require 'luanet.ffi.sys'

function NetFD:new(o)
  o = o or {} -- create table if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

function NetFD:close()
  sys.close(self.fd)
end

function NetFD:accept()
  -- TODO
end

-- socket: int
-- family: int
-- sotype: int
-- nettype: string
function M.new(sockfd, family, sotype, nettype)
  local fd = {
    fd = sockfd,
    family = family,
    sotype = sotype,
    nettype = nettype,
  }

  return NetFD:new(fd)
end

return M
