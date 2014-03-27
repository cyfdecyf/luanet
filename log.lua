local M = {}

-- Change the following variable to control whether to print specific
-- messages.
M.debugOn = true

function M.debug(...)
  if M.debugOn then
    io.write('[debug] ', string.format(...), '\n')
 end
end

return M

