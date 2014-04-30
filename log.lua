local M = {}

-- Change the following variable to control whether to print specific
-- messages.
local debug = true

function M.debug(...)
  if debug then
    if coroutine.running() then
      io.write('[debug] ', tostring(coroutine.running()), ' ',
        string.format(...), '\n')
    else
      io.write('[debug] thread: main ', string.format(...), '\n')
    end
 end
end

function M.debug_on()
  debug = true
end

function M.debug_off()
  debug = false
end

return M

