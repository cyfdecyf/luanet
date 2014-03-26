local M = {}

local sys = require 'luanet.ffi.sys'
local poll = require 'luanet.poll'
local util = require 'luanet.util'

local NetFD = {}
NetFD.__index = NetFD
NetFD.__gc = function (self)
  if not self.closed then self:close() end
end

function NetFD:new(fd)
  fd = fd or {}
  setmetatable(fd, self)
  return fd
end

function NetFD:init()
  local err
  self.pd, err = poll.open(self.fd)
  return err
end

function NetFD:set_addr(laddr, raddr)
  self.laddr = laddr
  self.raddr = raddr
end

function NetFD:close()
  sys.close(self.fd)
  self.closed = true
end

-- return: nfd, err
function NetFD:accept()
  while true do
    local fd, rsa, err = sys.accept(self.fd)
    if err == nil then break end

    if err == sys.EAGAIN then
      self.pd.wait_read()
    elseif err == sys.ECONNREFUSED then
      -- This means that a socket on the listen queue was closed
      -- before we Accept()ed it; it's a silly error, so try again.
    else
      return nil, util.strerror('accept')
    end
  end

  local nfd = NetFD:new{
    fd = fd, family = self.family, sotype = self.sotype,
    nettype = self.nettype,
  }
  local err = nfd:init()
  if err then
    nfd:close()
    return nil, util.strerror('accept->NetFD:init')
  end
  local lsa, err = sys.getsockname(nfd.fd)
  if err then
    nfd:close()
    return nil, util.strerror('accept->getsockname')
  end
  nfd:set_addr(sys.sockaddr_to_ip(lsa), sys.sockaddr_to_ip(rsa))
  return nfd, nil
end

-- socket: int
-- family: int
-- sotype: int
-- nettype: string
function M.new(sockfd, family, sotype, nettype)
  return NetFD:new{
    fd = sockfd,
    family = family,
    sotype = sotype,
    nettype = nettype,
  }
end

return M
