local sys = require 'luanet.ffi.sys'

local M = {}

--[[
For platform that does not have a fast path for setting non blocking and close
on exec.
--]]

function M.socket(family, sotype, proto)
  local sockfd, err = sys.socket(family, sotype, proto)
  if err then
    return nil, err
  end
  if sys.close_on_exec(sockfd) ~= nil then
    return nil, err
  end
  if sys.set_nonblock(sockfd, true) ~= nil then
    return nil, err
  end
  return sockfd, nil
end

-- Wrapper around the accept system call that marks the returned file
-- descriptor as nonblocking and close-on-exec.
function M.accept(sockfd)
  local nfd, sockaddr, err = sys.accept(sockfd)
  if err then
    return nil, nil, err
  end

  sys.close_on_exec(nfd)
  err = sys.set_nonblock(nfd, true)
  if err then
    sys.close(nfd)
    return nil, nil, err
  end
  return nfd, sockaddr, nil
end

return M
