local sys = require 'luanet.ffi.sys'
local syssock
if sys.os == 'OSX' then
  syssock = require 'luanet.sys_cloexec'
end
local poll = require 'luanet.poll'
local util = require 'luanet.util'
local netaddr = require 'luanet.addr'
local TCPAddr = netaddr.TCPAddr
local log = require 'luanet.log'
local OpError = require('luanet.error').OpError

local class = require 'pl.class'

class.NetFD()

function NetFD:_init(sockfd, family, sotype, nettype)
  assert(type(sockfd) == 'number', 'sockfd should be number')
  self.fd = sockfd
  self.family = family
  self.sotype = sotype
  self.nettype = nettype
end

function NetFD:__gc()
  if not self.closed then self:close() end
end

function NetFD:__tostring()
  local tb = { 'NetFD(fd=', self.fd, ':',
    tostring(self.laddr),
    '->',
    tostring(self.raddr),
    ')',
  }
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
    error(string.format('toaddr unknown data type %s', type(addr)))
  end

  return addrtype(addr)
end

function NetFD:set_addr(laddr, raddr)
  self.laddr = toaddr(self.nettype, laddr)
  self.raddr = toaddr(self.nettype, raddr)
end

function NetFD:close()
  sys.close(self.fd)
  if self.pd then
    self.pd:close()
  end
  self.closed = true
  log.debug('%s closed', self)
end

-- return: nfd, err
function NetFD:accept()
  local fd, rsa, err
  while true do
    fd, rsa, err = syssock.accept(self.fd)
    log.debug('%s accept fd=%s err: %s', self, fd, err)
    if err == nil then break end

    if err.errno == sys.EAGAIN then
      self.pd:wait_read()
    elseif err.errno == sys.ECONNREFUSED then
      -- This means that a socket on the listen queue was closed
      -- before we Accept()ed it; it's a silly error, so try again.
    else
      return nil, 'accept err: ' .. err
    end
  end

  local nfd = NetFD(fd, self.family, self.sotype, self.nettype)
  local err = nfd:init()
  if err then
    nfd:close()
    return nil, 'accept->NetFD:init err: ' .. err
  end
  local lsa, err = sys.getsockname(nfd.fd)
  if err then
    nfd:close()
    return nil, 'accept->getsockname err: ' .. err
  end
  local toaddr
  nfd:set_addr(sys.sockaddr_to_ip(lsa), sys.sockaddr_to_ip(rsa))
  log.debug('%s accept got %s', self, nfd)
  return nfd, nil
end

-- return: err
function NetFD:connect(raddr)
  local sa, err = sys.to_sockaddr(self.family, raddr)
  if err then return err end

  while true do
    local err = sys.connect(self.fd, sa)
    if err == nil or err.errno == sys.EISCONN then
      break
    end

    -- log.debug('%s connect err: %s', self, err)
    if err.errno ~= sys.EINPROGRESS and
      err.errno ~= sys.EALREADY and
      err.errno ~= sys.EINTR then
      log.debug('%s connect %s err: %s', self, raddr, err)
      return err
    end

    self.pd:wait_write()
  end
end

--[[
Because there's no slice mechanism in Lua, using a specific parameter to
specify the amount to read/write is more efficient.
--]]

local function chk_read_err(n, err, nfd)
  if n == 0 and err == nil and nfd.sotype ~= sys.SOCK_DGRAM and
    nfd.sotype ~= sys.SOCK_RAW then
    return sys.EOF
  end
  return err
end

--- Read at most n bytes into buffer.
-- @tparam Buffer
-- @number maximum bytes to read
-- @return #bytes read
-- @treturn OpError error
function NetFD:read(buf, n)
  local nr, err
  while true do
    nr, err = sys.read(self.fd, buf, n)
    log.debug('%s read %d got %d', self, n, nr)
    if err then
      nr = 0
      if err.errno == sys.EAGAIN then
        self.pd:wait_read()
        goto continue
      end
    end

    err = chk_read_err(nr, err, self)
    do break end
    ::continue::
  end
  assert(err ~= sys.EAGAIN)
  if err ~= nil and err ~= sys.EOF then
    err = OpError('read', self, err)
  end
  return nr, err
end

-- buf:
--   1. C buffer containing data
--   2. string, n is optional in this case
-- return: bytes written, err
-- If bytes written is less than n, err must be non-nil.
function NetFD:write(buf, n)
  local isstr = type(buf) == 'string'
  if isstr then n = buf:len() end

  local err
  local nn = 0 -- #bytes written
  while true do
    local nw, err = sys.write(self.fd, buf, n)
    log.debug('%s write %d written %d', self, n, nw)
    if nw > 0 then nn = nn + nw end
    n = n - nw
    if n == 0 then break end -- All data written, done.
    if isstr then
      -- Create buffer is string can't be written in one shot.
      buf = sys.Buffer(buf:sub(nw + 1))
      isstr = false
    else
      -- XXX advance buf, this relies on ffi's pointer arithmetic semantic.
      buf = buf + nw
    end

    if err == sys.EAGAIN then
      self.pd:wait_write()
      goto continue
    end

    if err ~= nil then break end
    if nw == 0 then
      err = sys.EUnexpectedEOF
      break
    end

    ::continue::
  end

  if err then
    err = OpError('write', self, err)
  end
  return nn, err
end

return NetFD
