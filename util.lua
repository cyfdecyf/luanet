local M = {}

function M.printf(...)
  io.write(string.format(...))
end

return M
