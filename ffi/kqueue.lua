local ffi = require 'ffi'
local C = ffi.C

require('luanet.ffi.kqueue_' .. ffi.os)

ffi.cdef[[
int kqueue(void);
int kevent(int kq, const struct kevent *changelist, int nchanges,
  struct kevent *eventlist, int nevents, const struct timespec *timeout);
]]

local M = {}

-- return kqueue descriptor and err
function M.kqueue()
  local kq = C.kqueue()
  if kq == -1 then
    return nil, ffi.errno()
  end
  return kq, nil
end

function M.ev_set(kev, ident, filter, flags, fflags, data, udata)
  kev.kev = kev
  kev.filter = filter
  kev.flags = flags
  kev.fflags = fflags
  kev.data = data
  kev.udata = udata
end

-- timeout: in seconds, can use floating point number, like 1.5
function M.new_timeout(timeout)
  local ts = ffi.new("struct timespec[1]")
  ts[0].tv_sec = timeout -- automatically convert to int
  ts[0].tv_nsec = (timeout % 1) * 1e8
  return ts
end

-- kq: kqueue
-- kev_change: array of struct kevent
-- kev_list: array
-- ts: timeout struct timespec
-- return: n and err
function M.kevent(kq, kev_change, nchange, kev_list, nkev, ts)
  local r = C.kevent(kq, kev_change, nchange, kev_list, nkev, ts)
  if r == -1 then
    return r, ffi.errno()
  end
  return r, nil
end

return M
