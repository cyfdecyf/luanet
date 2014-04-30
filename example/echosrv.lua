local net = require 'luanet'
local sys = net.sys
local Buffer = net.sys.Buffer
local TCPAddr = require('luanet.addr').TCPAddr
local printf = require('luanet.util').printf

net.debug_on()

function srv_client(cli)
  local bufsize = 64
  local buf = Buffer(bufsize)

  while true do
    local n, err = cli:read(buf, bufsize)
    if err then break end
    cli:write(buf, n)
  end

  if err and err ~= nil then
    io.write('client read error: ', err)
  end

  cli:close()
end

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

    net.run(srv_client, c)
  end
end

local srvaddr1 = TCPAddr('127.0.0.1', 1234)
local srvaddr2 = TCPAddr('127.0.0.1', 2345)

local srv1, err = net.run(echo_server, srvaddr1)
local srv2, err = net.run(echo_server, srvaddr2)

net.wait(srv1)
net.wait(srv2)
printf('server exited\n')
