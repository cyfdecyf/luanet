local sys = require 'luanet.ffi.sys'
local printf = require('luanet.util').printf
local debugOn = require('log').debugOn

local pollimp
if sys.os == 'OSX' then
  pollimp = require 'luanet.poll_kqueue'
end

local M = {}

local PollDesc = {}
PollDesc.__index = PollDesc

function PollDesc:new(pd)
  pd = pd or {}
  setmetatable(pd, self)
  pd.co = coroutine.running()
  assert(pd.co, 'PollDesc:new must be called inside coroutine')
  return pd
end

function PollDesc:close()
  pollimp.pollclose(self)
end

function PollDesc:wait_read()
  self.r = false
  self.waitr = true
  coroutine.yield()
end

function PollDesc:wait_write()
  self.w = false
  self.waitw = true
  coroutine.yield()
end

function M.init()
  pollimp.init()
end

-- return: PollDesc, err
function M.open(fd)
  local pd = PollDesc:new()

  pd.fd = fd
  pd.r = false -- ready for read
  pd.w = false -- ready for write
  pd.waitr = false -- wait to read
  pd.waitw = false -- wait to write

  local err = pollimp.pollopen(pd)
  return pd, err
end

-- Create and run the coroutine.
-- return: coroutine, err
function M.run(f, ...)
  local co = coroutine.create(f)
  local succ, err = coroutine.resume(co, ...)
  if not succ then
    printf('run error: %s\n', err)
    if debugOn then io.write(debug.traceback(co)) end
  end
  return co, err
end

-- Wait for events and resume corresponding coroutine.
-- Break if specified coroutine finishes.
function M.poll(block, co)
  while true do
    local pds, n = pollimp.poll(block)
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
        util.printf('coroutine for %s error %s', pd:string(), err)
        if debugOn then
          io.write(debug.traceback(pd.co))
        end
      end
      if coroutine.status(pd.co) == 'dead' then
        pd:close()
        if co == pd.co then break end
      end
    end
  end
end

function M.wait(co)
  while coroutine.status(co) ~= 'dead' do
    M.poll(true, co)
  end
end

return M
