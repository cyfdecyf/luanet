local sys = require 'luanet.ffi.sys'
local printf = require('luanet.util').printf
local log = require 'luanet.log'

local class = require 'pl.class'

local pollimp
if sys.os == 'OSX' then
  pollimp = require 'luanet.poll_kqueue'
end

local M = {}

local polldesc_cache

M.PollDesc = class.PollDesc()

function PollDesc:_init()
  if polldesc_cache == nil then
    polldesc_cache = setmetatable({}, self)
  end
  local pd = polldesc_cache
  polldesc_cache = pd.link
  return pd
end

-- PollDesc belongs to some specific NetFD, so close should be called by NetFD.
function PollDesc:close()
  pollimp.pollclose(self)
  self.link = polldesc_cache
  polldesc_cache = self
end

--[[
Always set coroutine to the one calling wait_read/write.
Because the coroutine creating the socket may not be the one actually doing I/O
on it.
TODO: allow main thread to wait read/write.
]]

function PollDesc:wait_read()
  self.co = coroutine.running()
  assert(self.co, 'calling wait_read in main thread')
  self.r = false
  self.waitr = true
  log.debug('fd=%d wait_read yield', self.fd)
  coroutine.yield()
  log.debug('fd=%d wait_read resumed', self.fd)
end

function PollDesc:wait_write()
  self.co = coroutine.running()
  assert(self.co, 'calling wait_write in main thread')
  self.w = false
  self.waitw = true
  log.debug('fd=%d wait_write yield', self.fd)
  coroutine.yield()
  log.debug('fd=%d wait_write resumed', self.fd)
end

function M.init()
  pollimp.init()
end

-- return: PollDesc, err
function M.open(fd)
  local pd = PollDesc()

  pd.fd = fd
  pd.r = false -- ready for read
  pd.w = false -- ready for write
  pd.waitr = false -- wait to read
  pd.waitw = false -- wait to write
  pd.co = nil

  local err = pollimp.pollopen(fd, pd)
  if err then
    return nil, err
  end
  return pd, nil
end

-- Create and run the coroutine.
-- return: coroutine, err
function M.run(f, ...)
  local co = coroutine.create(f)
  local succ, err = coroutine.resume(co, ...)
  if not succ then
    printf('run error: %s\n', err)
    io.write(debug.traceback(co))
  end
  return co, err
end

-- Wait for events and resume corresponding coroutine.
-- Break if specified coroutine finishes.
function M.poll(block, co)
  while true do
    log.debug('poll block=%s co=%s', block, co)
    local pds, n = pollimp.poll(block)
    log.debug('poll got %d ready PollDesc', n)
    if n == 0 then break end
    for i=1,n do
      local pd = pds[i]
      local succ = true
      local err
      assert(coroutine.status(pd.co) ~= 'dead', "ready polldesc's coroutine is dead")
      if pd.r and pd.waitr then
        log.debug('poll resume %s wait_read', pd.co)
        succ, err = coroutine.resume(pd.co)
      elseif pd.w and pd.waitw then
        log.debug('poll resume %s wait_write', pd.co)
        succ, err = coroutine.resume(pd.co)
      else
        log.debug('%s fd=%s ready for not matching op', pd.co, pd.fd)
      end
      if not succ then
        printf('coroutine %s for fd=%d err: %s\n%s', pd.co, pd.fd,
          err, debug.traceback(pd.co))
      end
      if coroutine.status(pd.co) == 'dead' then
        if co == pd.co then goto done end
      end
    end
  end
  ::done::
end

-- Wait for a specifc coroutine finish.
function M.wait(co)
  while coroutine.status(co) ~= 'dead' do
    M.poll(true, co)
  end
end

return M
