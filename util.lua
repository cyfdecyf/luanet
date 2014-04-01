local util = require 'luanet.ffi.util'

local M = {}

function M.strerror(...)
  local arg = {...}
  local errmsg = util.strerror()
  if #arg == 0 then
    return errmsg
  end
  return string.format(...) .. ': ' .. errmsg
end

function M.printf(...)
  io.write(string.format(...))
end

M.bzero = util.bzero

return M
