local sys = require 'luanet.ffi.sys'
local sockopt = require 'luanet.sockopt_bsd'
local NetFD = require 'luanet.fd_unix'
local log = require 'luanet.log'

local syssock
if sys.os == 'OSX' then
  syssock = require 'luanet.sys_cloexec'
end

local M = {}

local function bind(nfd, addr)
  local sa, err = sys.to_sockaddr(nfd.family, addr)
  if err then return err end
  return sys.bind(nfd.fd, sa)
end

-- return: err
local function listen_stream(nfd, laddr, backlog)
  if sockopt.set_default_listener_sockopts(nfd.fd) ~= nil then
    return string.format('set_default_listener_sockopt %s err: %s', nfd, err)
  end

  local err
  local errmsg = function(msg)
    return string.format('%s %s err: %s', msg, nfd, err)
  end
  err = bind(nfd, laddr)
  if err then return errmsg('listen_stream->bind') end

  err = sys.listen(nfd.fd, backlog)
  if err then return errmsg('listen_stream->listen') end

  err = nfd:init()
  if err then return errmsg('listen_stream->nfd:init') end

  local sa = sys.getsockname(nfd.fd)
  nfd:set_addr(sa, nil)
end

local function dial(nfd, laddr, raddr)
  log.debug('dial %s %s->%s', nfd, laddr, raddr)
  if laddr ~= nil then
    local err = bind(nfd, laddr)
    if err then
      return string.format('dial->bind %s err: %s', nfd, err)
    end
  end

  local err = nfd:init()
  if err then return err end
  if raddr ~= nil then
    err = nfd:connect(raddr)
    if err then return err end
  end

  local lsa = sys.getsockname(nfd.fd)
  local rsa = sys.getpeername(nfd.fd)
  nfd:set_addr(lsa, rsa)
end

-- nettype: 'tcp'
-- laddr: { ip: '127.0.0.1', port: 1024 }
--   if not nil, bind and then listen
-- return: netfd, err
function M.socket(nettype, family, sotype, proto, laddr, raddr)
  assert(laddr ~= nil or raddr ~= nil)
  local sockfd, err = syssock.socket(family, sotype, proto)
  if err then
    return nil, 'create_socket err:' .. err
  end
  err = sockopt.set_default_sockopts(sockfd)
  if err then
    sys.close(sockfd)
    return nil, 'set_default_sockopts err: ' .. err
  end

  local nfd = NetFD(sockfd, family, sotype, nettype)
  if laddr ~= nil and raddr == nil then
    if sotype == sys.SOCK_STREAM then
      local err = listen_stream(nfd, laddr, sys.SOMAXCONN)
      if err then
        nfd:close()
        return nil, err
      end
      return nfd, nil
    end
  end
  err = dial(nfd, laddr, raddr)
  if err then
    nfd:close()
    return nil, err
  end
  return nfd, nil
end

return M
