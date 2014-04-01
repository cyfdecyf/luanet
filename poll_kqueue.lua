local syskq = require 'luanet.ffi.kqueue'
local sys = require 'luanet.ffi.sys'
local bit = require 'bit'
local log = require 'luanet.log'

local M = {}

local kq

function M.init()
  local err
  kq, err = syskq.kqueue()
  if err then
    error('kqueue failed')
  end
  sys.close_on_exec(kq)
end

-- Mapping between fd and polldesc.
-- luajit ffi can't convert lua table to void *, so we can't
-- store polldesc in kevent's udata field.
local polldesc_tbl = {}

-- pd: PollDesc
function M.pollopen(fd, pd)
  local ev = syskq.new_kevent(2)
  ev[0].ident = fd
  ev[0].filter = syskq.EVFILT_READ
  ev[0].flags = bit.bor(syskq.EV_ADD, syskq.EV_CLEAR)
  ev[0].fflags = 0
  ev[0].data = 0

  ev[1] = ev[0]
  ev[1].filter = syskq.EVFILT_WRITE

  local r = syskq.kevent(kq, ev, 2, nil, 0, nil)
  if r == -1 then
    log.debug('poll_kqueue open fd=%d failed', fd)
    return ffi.errno()
  end
  polldesc_tbl[fd] = pd
  log.debug('poll_kqueue open fd=%d', fd)
end

function M.pollclose(pd)
  -- Calling close() on fd will remove kevents that
  -- reference the descriptor.
  polldesc_tbl[pd.fd] = nil
end

local n_pollev = 64
local pollev = syskq.new_kevent(n_pollev)
local ready_pd = {}

-- return: ready poll desc
function M.poll(block)
  local lasterr, ts

  if not block then
    ts = syskq.new_timeout(0)
  else
    -- TODO: if there are timer or read/write deadline, should also set a
    -- timeout
  end

  local n, err
  while true do
    n, err = syskq.kevent(kq, nil, 0, pollev, n_pollev, ts)
    if err == nil then break end
    if err ~= sys.EINTR and err ~= lasterr then
      io.write(string.format('kevent on fd %d failed with %d', kq, err))
      lasterr = err
    end
  end

  for i=0,n-1 do
    local ev = pollev[i]
    local pd = polldesc_tbl[tonumber(ev.ident)]
    assert(pd, 'poll should not get nil pd')
    ready_pd[i+1] = pd
    if ev.filter == syskq.EVFILT_READ then
      pd.r = true
    elseif ev.filter == syskq.EVFILT_WRITE then
      pd.w = true
    end
  end
  return ready_pd, n
end

return M
