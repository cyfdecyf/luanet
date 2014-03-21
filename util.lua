local ffi = require 'ffi'
local C = ffi.C

ffi.cdef[[
void perror(const char *s);
char *strerror(int errnum);

void bzero(void *s, size_t n);
]]

local M = {}

function M.strerror(...)
  local errmsg = ffi.string(C.strerror(ffi.errno()))
  local s = string.format(...)
  return s .. ': ' .. errmsg
end

function M.bzero(buf, size)
  C.bzero(buf, size)
end

return M
