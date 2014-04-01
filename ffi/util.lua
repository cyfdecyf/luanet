local ffi = require 'ffi'
local C = ffi.C

local M = {}

ffi.cdef[[
char *strerror(int errnum);
void bzero(void *s, size_t n);
]]

function M.strerror()
  return ffi.string(C.strerror(ffi.errno()))
end

function M.bzero(buf, size)
  C.bzero(buf, size)
end

return M
