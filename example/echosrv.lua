local net = require 'luanet'
local addr = require 'luanet.addr'
local printf = require('luanet.util').printf

net.debug_on()

function echo_server(srvaddr)
  printf('server listening %s\n', srvaddr)
  local ln, err = net.listen('tcp', srvaddr)
  if err then
    print('listen error: %s\n', err)
    return err
  end

  while true do
    local c, err = ln:accept()
    if err then
      print(err)
      return err
    end
    printf('new client %s\n', c.raddr)
    c:close()
  end
end

local srvaddr1 = addr.TCPAddr:new('127.0.0.1', 1234)
local srvaddr2 = addr.TCPAddr:new('127.0.0.1', 2345)

local srv1, err = net.run(echo_server, srvaddr1)
local srv2, err = net.run(echo_server, srvaddr2)

net.wait(srv1)
net.wait(srv2)
printf('server exited\n')
