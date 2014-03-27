local sys = require 'luanet.ffi.sys'
local poll = require 'luanet.poll'
local util = require 'luanet.util'
local netaddr = require 'luanet.addr'
local TCPAddr = netaddr.TCPAddr

local NetFD = {}
NetFD.__index = NetFD
NetFD.__gc = function (self)
  if not self.closed then self:close() end
end

function NetFD:new(sockfd, family, sotype, nettype)
  assert(type(sockfd) == 'number', 'sockfd should be number')
  local o = {
    fd = sockfd,
    family = family,
    sotype = sotype,
    nettype = nettype,
  }
  return setmetatable(o, self)
end

function NetFD:init()
  local err
  self.pd, err = poll.open(self.fd)
  return err
end

function NetFD:set_addr(laddr, raddr)
  local addrtype
  if self.nettype == 'tcp' then
    addrtype = TCPAddr
  end
  if laddr then self.laddr = addrtype:new(laddr) end
  if raddr then self.raddr = addrtype:new(raddr) end
end

function NetFD:close()
  sys.close(self.fd)
  self.closed = true
end

-- return: nfd, err
function NetFD:accept()
  local fd, rsa, err
  while true do
    fd, rsa, err = sys.accept(self.fd)
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

  local nfd = NetFD:new(fd, self.family, self.sotype, self.nettype)
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
  local toaddr
  nfd:set_addr(sys.sockaddr_to_ip(lsa), sys.sockaddr_to_ip(rsa))
  return nfd, nil
end

return NetFD
