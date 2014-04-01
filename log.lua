local M = {}

-- Change the following variable to control whether to print specific
-- messages.
local debug = true

function M.debug(...)
  if debug then
    io.write('[debug] ', string.format(...), '\n')
 end
end

function M.debug_on()
  debug = true
end

function M.debug_off()
  debug = false
end

return M

