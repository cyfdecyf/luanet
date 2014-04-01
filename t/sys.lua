local sys = require 'luanet.ffi.sys'
local util = require 'luanet.util'
local ffi = require 'ffi'
local C = ffi.C

local M = {}

function M.test_addr_convert()
  local ipaddr = { ip = '127.0.0.1', port = 1234 }
  local sockaddr, err = sys.ip_to_sockaddr(sys.AF_INET, ipaddr)
  assert_nil(err, 'ip_to_sockaddr test')

  local ipback = sys.sockaddr_to_ip(sockaddr)
  assert_true(ipback.ip == ipaddr.ip, 'converted back ip not match')
  assert_true(ipback.port == ipaddr.port, 'converted back port not match')
end

function M.test_sys_socket()
  local fd, err = sys.socket(sys.AF_INET, sys.SOCK_STREAM, 0)
  assert_not_nil(fd)
  assert_nil(err, 'socket')

  err = sys.close_on_exec(fd)
  assert_nil(err, 'close_on_exec')

  local fdflag = C.fcntl(fd, C.F_GETFD)
  assert_not_equal(fdflag, -1, 'F_GETFD')
  assert_true(bit.band(fdflag, C.FD_CLOEXEC) ~= 0, 'CLOEXEC flag not set')

  err = sys.set_nonblock(fd, true)
  assert_nil(err, 'set_nonblock true')
  local flag2 = C.fcntl(fd, C.F_GETFL)
  assert_not_equal(flag2, -1, 'F_GETFL')
  assert_true(bit.band(flag2, C.O_NONBLOCK) ~= 0, 'NONBLOCK flag not set')

  local ipaddr = { ip = '127.0.0.1', port = 8765 }
  local sockaddr, err = sys.ip_to_sockaddr(sys.AF_INET, ipaddr)
  assert_nil(err, 'ip_to_sockaddr')

  err = sys.bind(fd, sockaddr)
  assert_nil(err, 'bind')

  err = sys.setsockopt(fd, sys.SOL_SOCKET, sys.SO_REUSEADDR, 1)
  assert_nil(err, 'setsockopt')

  err = sys.listen(fd, sys.SOMAXCONN)
  assert_nil(err, 'listen')

  -- test non-blocking accept
  _, _, err = sys.accept(fd)
  assert_not_nil(err, 'connect')

  err = sys.set_nonblock(fd, false)
  assert_nil(err, 'set_nonblock false')

  -- fork to test accept, connect, read & write
  local r = ffi.C.fork()
  if r == 0 then
    -- child sleep 0.1 second and then connect
    ffi.C.usleep(100000);

    assert_nil(sys.close(fd))
    local srvfd, err = sys.socket(sys.AF_INET, sys.SOCK_STREAM, 0)
    assert_nil(err, 'socket client')

    err = sys.connect(srvfd, sockaddr)
    assert_nil(err, 'connect')

    local bufsize = 50
    local buf = sys.new_buf(bufsize)
    for i=0,bufsize-1 do
      buf[i] = i
    end

    local n, err = sys.write(srvfd, buf, bufsize)
    assert_nil(err)

    os.exit(0)
  else
    -- parent call accept
    local clifd, sa, err = sys.accept(fd)
    assert_nil(err, 'accept')

    local bufsize = 10
    local buf = sys.new_buf(bufsize)

    local c = 0
    while true do
      local n, err = sys.read(clifd, buf, bufsize)
      if err == sys.EOF then break end
      assert_nil(err, 'read')
      for i=0,n-1 do
        assert_true(buf[i] == c,
          string.format('read value not match exp=%d got=%d', c, buf[i]))
        c = c + 1
      end
    end
  end
  sys.close(fd)
end

return M
