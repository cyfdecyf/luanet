local sys = require 'luanet.ffi.sys'
local printf = require('luanet.util').printf
local log = require 'luanet.log'

local pollimp
if sys.os == 'OSX' then
  pollimp = require 'luanet.poll_kqueue'
end

local M = {}

local PollDesc = setmetatable({}, {
  __call = function (self)
    return setmetatable({}, self)
  end
})
PollDesc.__index = PollDesc

function PollDesc:close()
  pollimp.pollclose(self)
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
  log.debug('fd %s wait_read yield', self.fd)
  coroutine.yield()
  log.debug('fd %s wait_read resumed', self.fd)
end

function PollDesc:wait_write()
  self.co = coroutine.running()
  assert(self.co, 'calling wait_write in main thread')
  self.w = false
  self.waitw = true
  log.debug('fd %s wait_write yield', self.fd)
  coroutine.yield()
  log.debug('fd %s wait_write resumed', self.fd)
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
    log.debug('poll got %d ready pd', n)
    if n == 0 then break end
    for i=1,n do
      local pd = pds[i]
      local succ, err
      if pd.r and pd.waitr then
        succ, err = coroutine.resume(pd.co)
      elseif pd.w and pd.waitw then
        succ, err = coroutine.resume(pd.co)
      end
      if not succ then
        printf('coroutine %s for fd=%d err: %s\n%s', pd.co, pd.fd,
          err, debug.traceback(pd.co))
      end
      if coroutine.status(pd.co) == 'dead' then
        pd:close()
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
