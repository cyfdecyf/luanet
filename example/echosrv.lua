local net = require 'luanet'

local srvaddr = { ip = '127.0.0.1', port = 1234 }

function echo_server()
  local ln, err = net.listen('tcp', srvaddr)
  if err then
    print('listen error', err)
    return err
  end

  local c, err = ln:accept()
  if err then
    print('accept error', err)
    return err
  end
end

local srv = coroutine.create(echo_server)
coroutine.resume(srv)

net.wait(srv)
