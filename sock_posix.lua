local sys = require 'luanet.ffi.sys'
local sockopt = require 'luanet.sockopt_bsd'
local netfd = require 'luanet.fd_unix'
local util = require 'luanet.util'

local syssock
if sys.os == 'OSX' then
  syssock = require 'luanet.sys_cloexec'
end

local M = {}

-- return: err
local function listen_stream(nfd, laddr, backlog)
  if sockopt.set_default_listener_sockopts(nfd.fd) ~= nil then
    return util.strerror('set_default_listener_sockopt fd=%d', nfd.fd)
  end

  local errmsg = function(msg)
    return util.strerror('%s fd=%d ip=%s port=%d', msg,
      nfd.fd, laddr.ip, laddr.port)
  end
  local sa, err = sys.ip_to_sockaddr(nfd.family, laddr)
  if err then return err end
  err = sys.bind(nfd.fd, sa)
  if err then return errmsg('listen_stream->bind') end

  err = sys.listen(nfd.fd, backlog)
  if err then return errmsg('listen_stream->listen') end

  err = nfd:init()
  if err then return errmsg('listen_stream->nfd:init') end
  nfd:set_addr(laddr, nil)
end

-- nettype: 'tcp'
-- laddr: table {ip: '127.0.0.1', port: 1024}
--   if not nil, bind and then listen
-- return: netfd, err
function M.socket(nettype, family, sotype, proto, laddr, raddr)
  local sockfd, err = syssock.socket(family, sotype, proto)
  if err then
    return nil, util.strerror('create_socket')
  end
  err = sockopt.set_default_sockopts(sockfd)
  if err then
    return nil, util.strerror('set_default_sockopts')
  end

  local nfd = netfd.new(sockfd, family, sotype, nettype)
  if laddr ~= nil and raddr == nil then
    if sotype == sys.SOCK_STREAM then
      local err = listen_stream(nfd, laddr, sys.SOL_SOCKET)
      if err then
        nfd:close()
        return nil, err
      end
      return nfd, nil
    end
  end
end

return M
