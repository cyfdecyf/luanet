local ffi = require 'ffi'
local C = ffi.C

require('luanet.ffi.kqueue_' .. ffi.os)

ffi.cdef[[
int kqueue(void);
int kevent(int kq, const struct kevent *changelist, int nchanges,
  struct kevent *eventlist, int nevents, const struct timespec *timeout);
]]

local M = {}

M.EVFILT_READ = C.EVFILT_READ
M.EVFILT_WRITE = C.EVFILT_WRITE
M.EVFILT_AIO = C.EVFILT_AIO
M.EVFILT_TIMER = C.EVFILT_TIMER

M.EV_ADD = C.EV_ADD
M.EV_DELETE = C.EV_DELETE
M.EV_DISABLE  = C.EV_DISABLE
M.EV_RECEIPT = C.EV_RECEIPT

M.EV_ONSHOT = C.EV_ONSHOT
M.EV_CLEAR = C.EV_CLEAR
M.EV_DISPATCH = C.EV_DISPATCH

M.EV_EOF = C.EV_EOF
M.EV_ERROR = C.EV_ERROR

-- return kqueue descriptor and err
function M.kqueue()
  local kq = C.kqueue()
  if kq == -1 then
    return nil, ffi.errno()
  end
  return kq, nil
end

function M.new_kevent(n)
  return ffi.new('struct kevent[?]', n)
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
