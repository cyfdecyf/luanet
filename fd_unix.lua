local sys = require 'luanet.ffi.sys'
local poll = require 'luanet.poll'
local util = require 'luanet.util'
local netaddr = require 'luanet.addr'
local TCPAddr = netaddr.TCPAddr
local log = require 'luanet.log'

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

function NetFD:__tostring()
  local tb = { 'NetFD (', self.fd, ') ' }
  if self.laddr then
    tb[#tb + 1] = string.format('%s:%d', self.laddr.ip, self.laddr.port)
  end
  if self.raddr then
    tb[#tb + 1] = string.format('->%s:%d', self.raddr.ip, self.raddr.port)
  end
  return table.concat(tb)
end

function NetFD:init()
  local err
  self.pd, err = poll.open(self.fd)
  return err
end

local function toaddr(nettype, addr)
  if addr == nil then return nil end

  local addrtype
  if nettype == 'tcp' then
    addrtype = TCPAddr
  end

  if type(addr) == 'table' then
  elseif type(addr) == 'cdata' then
    addr = sys.sockaddr_to_ip(addr)
  else
    error(util.strerror('toaddr unknown data type %s', type(addr)))
  end

  return addrtype:new(addr)
end

function NetFD:set_addr(laddr, raddr)
  self.laddr = toaddr(self.nettype, laddr)
  self.raddr = toaddr(self.nettype, raddr)
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
    log.debug('fd %d accept return %s', self.fd, util.strerror())
    if err == nil then break end

    if err == sys.EAGAIN then
      self.pd:wait_read()
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
