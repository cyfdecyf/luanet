local ffi = require 'ffi'
local C = ffi.C
local bit = require('bit')

--[[
Note for network address:
sockaddr means struct sockaddr in C, created by ffi library.
--]]

-- It's better to require os specific struct and typedef first before calling
-- cdef for general functions.
require('luanet.ffi.' .. ffi.os)

ffi.cdef[[
uint32_t htonl(uint32_t hostlong);
uint16_t htons(uint16_t hostshort);
uint32_t ntohl(uint32_t netlong);
uint16_t ntohs(uint16_t netshort);

int inet_aton(const char *cp, struct in_addr *pin);
char *inet_ntoa(struct in_addr in);

int getsockopt(int sockfd, int level, int optname, const void *optval, socklen_t *optlen);
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);

int socket(int domain, int type, int protocol);

int bind(int sockfd, const struct sockaddr *address, socklen_t address_len);
int listen(int sockfd, int backlog);
int accept(int sockfd, struct sockaddr *restrict address, socklen_t *restrict address_len);
int connect(int sockfd, const struct sockaddr *address, socklen_t address_len);

ssize_t read(int fildes, void *buf, size_t nbyte);
ssize_t write(int fildes, const void *buf, size_t nbyte);

int close(int fildes);

int fcntl(int fd, int cmd, ...);

pid_t fork(void);
int usleep(useconds_t useconds);
]]

-- No cross function invocation in this file, so use this module style.
local M = {}

M.EOF = {} -- use a table to create a unique object

M.SOCK_STREAM = C.SOCK_STREAM
M.SOCK_DGRAM = C.SOCK_DGRAM
M.SOCK_RAW = C.SOCK_RAW

M.AF_UNSPEC = C.AF_UNSPEC
M.AF_UNIX = C.AF_UNIX
M.AF_INET = C.AF_INET

M.SO_DEBUG = C.SO_DEBUG
M.SO_ACCEPTCONN = C.SO_ACCEPTCONN
M.SO_REUSEADDR = C.SO_REUSEADDR
M.SO_KEEPALIVE = C.SO_KEEPALIVE
M.SO_DONTROUTE = C.SO_DONTROUTE
M.SO_BROADCAST = C.SO_BROADCAST

M.INADDR_ANY = C.INADDR_ANY

M.SOMAXCONN = C.SOMAXCONN
M.SOL_SOCKET = C.SOL_SOCKET

M.os = ffi.os

local sockaddr_type = ffi.typeof('struct sockaddr *')
local sockaddr_in_type = ffi.typeof('struct sockaddr_in *')
local sockaddr_in1_type = ffi.typeof('struct sockaddr_in[1]')

-- addr: ipv4: { ip = '127.0.0.1', port = 8080 }
-- return: sockaddr, err
function M.ip_to_sockaddr(family, addr)
  if family == C.AF_INET then
    local sa = sockaddr_in1_type()
    C.bzero(sa, ffi.sizeof(sa))
    sa[0].sin_family = C.AF_INET
    sa[0].sin_port = C.htons(addr.port);
    local r = C.inet_aton(addr.ip, sa[0].sin_addr)
    if r ~= 1 then
      return nil, ffi.errno()
    end
    return sa, nil
  end
  error('ip_to_sockaddr family not supported')
end

-- sockaddr: struct sockaddr
-- return: ipaddr
function M.sockaddr_to_ip(sockaddr)
  local sa = ffi.cast(sockaddr_type, sockaddr)
  if sa.sa_family == C.AF_INET then
    sa = ffi.cast(sockaddr_in_type, sockaddr)
    return {
      ip = ffi.string(C.inet_ntoa(sa.sin_addr)),
      port = C.ntohs(sa.sin_port)
    }
  end
  error('sockaddr_to_ip family not supported')
end

-- return: sockfd, err
function M.socket(domain, type, protocol)
  local fd = C.socket(domain, type, protocol)
  if fd == -1 then
    return nil, ffi.errno()
  end
  return fd, nil
end

local sockopt_newtype = {
  [M.SO_BROADCAST] = ffi.typeof('int32_t[1]'),
  [M.SO_REUSEADDR] = ffi.typeof('int32_t[1]'),
}

-- return: err
function M.setsockopt(sockfd, level, option_name, option_value)
  assert(sockopt_newtype[option_name])
  local val = ffi.new(sockopt_newtype[option_name], option_value)
  local r = C.setsockopt(sockfd, level, option_name, val, ffi.sizeof(val))
  return r == -1 and ffi.errno() or nil
end

-- sockaddr: { ip: '127.0.0.1'1, port = 1234 }
function M.bind(sockfd, sockaddr)
  local r = C.bind(sockfd, ffi.cast(sockaddr_type, sockaddr), ffi.sizeof(sockaddr))
  return r == -1 and ffi.errno() or nil
end

-- return: err
function M.listen(sockfd, backlog)
  local r = C.listen(sockfd, backlog)
  return r == -1 and ffi.errno() or nil
end

local sockaddr_big1_type = ffi.typeof('sockaddr_big[1]')
local socklen_t1_type = ffi.typeof('socklen_t[1]')

-- return: client fd, sockaddr, err
function M.accept(sockfd)
  local sa = sockaddr_big1_type()
  local lsa = ffi.new(socklen_t1_type, ffi.sizeof(sa))
  local fd = C.accept(sockfd, ffi.cast(sockaddr_type, sa), lsa)
  if fd == -1 then
    return nil, nil, ffi.errno()
  end
  return fd, sa, nil
end

-- return: err
function M.connect(sockfd, sockaddr)
  local r = C.connect(sockfd, ffi.cast(sockaddr_type, sockaddr),
    ffi.sizeof(sockaddr))
  return r == -1 and ffi.errno() or nil
end

function M.new_buf(n)
  return ffi.new('uint8_t[?]', n)
end

function M.read(fd, buf, n)
  local r = tonumber(C.read(fd, buf, n))
  if r == -1 then
    return 0, ffi.errno()
  elseif r == 0 then
    return 0, M.EOF
  end
  return r, nil
end

function M.write(fd, buf, n)
  -- return value bigger than int32 would be cdata
  local r = tonumber(C.write(fd, buf, n))
  if r == -1 then
    return r, ffi.errno()
  end
  assert(r == n, 'write: written bytes ~= requested')
  return r, nil
end

-- return: err
function M.close(sockfd)
  local r = C.close(sockfd)
  return r == -1 and ffi.errno() or nil
end

-- return: err
function M.set_nonblock(fd, nonblocking)
  local flag = C.fcntl(fd, C.F_GETFL)
  if flag == -1 then
    return ffi.errno()
  end

  if nonblocking then
    flag = bit.bor(flag, C.O_NONBLOCK)
  else
    flag = bit.band(flag, bit.bnot(C.O_NONBLOCK))
  end
  local err = C.fcntl(fd, C.F_SETFL, flag)
  if err == -1 then
    return ffi.errno()
  end
end

-- return: err
function M.close_on_exec(fd)
  local r = C.fcntl(fd, C.F_SETFD, C.FD_CLOEXEC)
  return r == -1 and ffi.errno() or nil
end

return M
