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

return M
